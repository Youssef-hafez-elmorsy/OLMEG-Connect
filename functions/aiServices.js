const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const OPENAI_RESPONSES_URL = 'https://api.openai.com/v1/responses';
const DEFAULT_AI_MODEL = 'gpt-5.4-mini';

const BLOCKED_TERMS = [
  'weapon',
  'gun',
  'rifle',
  'pistol',
  'knife',
  'drugs',
  'cocaine',
  'fake id',
  'passport',
  'stolen',
  'counterfeit',
  'hack',
  'explosive',
];

const REVIEW_SCHEMA = {
  name: 'product_moderation_review',
  type: 'json_schema',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      approved: { type: 'boolean' },
      confidence: { type: 'number', minimum: 0, maximum: 1 },
      riskScore: { type: 'number', minimum: 0, maximum: 1 },
      riskLevel: { type: 'string', enum: ['low', 'medium', 'high'] },
      suggestedAction: {
        type: 'string',
        enum: ['approve', 'admin_review', 'reject', 'escalate'],
      },
      reasons: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 6,
      },
      signals: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 8,
      },
      sellerHints: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 5,
      },
    },
    required: [
      'approved',
      'confidence',
      'riskScore',
      'riskLevel',
      'suggestedAction',
      'reasons',
      'signals',
      'sellerHints',
    ],
  },
};

const SEARCH_INTENT_SCHEMA = {
  name: 'marketplace_search_intent',
  type: 'json_schema',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      normalizedQuery: { type: 'string' },
      expandedTerms: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 12,
      },
      categoryHints: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 5,
      },
      buyerIntent: {
        type: 'string',
        enum: ['browse', 'compare', 'deal', 'specific_item', 'local_pickup'],
      },
    },
    required: ['normalizedQuery', 'expandedTerms', 'categoryHints', 'buyerIntent'],
  },
};

const RECOMMENDATION_SCHEMA = {
  name: 'buyer_recommendations',
  type: 'json_schema',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      productIds: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 12,
      },
      explanation: { type: 'string' },
    },
    required: ['productIds', 'explanation'],
  },
};

const SELLER_HINTS_SCHEMA = {
  name: 'seller_listing_hints',
  type: 'json_schema',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      titleSuggestions: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 3,
      },
      descriptionSuggestions: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 5,
      },
      pricingSignals: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 4,
      },
      trustSignals: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 4,
      },
    },
    required: [
      'titleSuggestions',
      'descriptionSuggestions',
      'pricingSignals',
      'trustSignals',
    ],
  },
};

const ADMIN_ASSISTANT_SCHEMA = {
  name: 'admin_assistant_answer',
  type: 'json_schema',
  strict: true,
  schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      summary: { type: 'string' },
      nextActions: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 6,
      },
      risks: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 6,
      },
      collectionsToInspect: {
        type: 'array',
        items: { type: 'string' },
        maxItems: 8,
      },
    },
    required: ['summary', 'nextActions', 'risks', 'collectionsToInspect'],
  },
};

function openAiConfig() {
  const runtimeConfig = functions.config().openai || {};
  return {
    apiKey: process.env.OPENAI_API_KEY || runtimeConfig.api_key,
    model: process.env.OPENAI_MODEL || runtimeConfig.model || DEFAULT_AI_MODEL,
  };
}

function requiredString(value, name) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `${name} is required.`,
    );
  }
  return value.trim();
}

function optionalString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function clamp01(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return 0;
  return Math.min(Math.max(number, 0), 1);
}

function arrayOfStrings(value) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item) => typeof item === 'string' && item.trim().length > 0)
    .map((item) => item.trim())
    .slice(0, 8);
}

function heuristicReview({ title, description, price }) {
  const reasons = [];
  const signals = [];
  const sellerHints = [];
  const text = `${title} ${description}`.toLowerCase();

  if (title.trim().length < 3) {
    reasons.push('Title is too short.');
    sellerHints.push('Use a specific title with brand, product type, and condition.');
  }

  if (description.trim().length < 10) {
    reasons.push('Description is too short.');
    sellerHints.push('Add condition, measurements, defects, warranty, and what is included.');
  } else if (description.trim().length < 40) {
    sellerHints.push('A longer description will help buyers trust the listing.');
  }

  if (!Number.isFinite(price) || price <= 0) {
    reasons.push('Price must be greater than zero.');
    signals.push('invalid_price');
  }

  BLOCKED_TERMS.forEach((term) => {
    if (text.includes(term)) {
      reasons.push(`Possible restricted item: "${term}".`);
      signals.push(`restricted_term:${term}`);
    }
  });

  const riskScore = reasons.length === 0 ? 0.08 : Math.min(0.92, 0.35 + reasons.length * 0.18);
  const riskLevel = riskScore >= 0.7 ? 'high' : riskScore >= 0.35 ? 'medium' : 'low';
  const suggestedAction = riskLevel === 'low'
    ? 'approve'
    : riskLevel === 'medium'
      ? 'admin_review'
      : 'escalate';

  return {
    approved: suggestedAction === 'approve',
    confidence: reasons.length === 0 ? 0.88 : 0.78,
    riskScore,
    riskLevel,
    suggestedAction,
    reasons,
    signals,
    sellerHints,
    provider: 'local_rules',
    model: 'local_rules_v1',
  };
}

function normalizedReview(raw, fallback) {
  const riskScore = clamp01(raw.riskScore);
  const riskLevel = ['low', 'medium', 'high'].includes(raw.riskLevel)
    ? raw.riskLevel
    : riskScore >= 0.7
      ? 'high'
      : riskScore >= 0.35
        ? 'medium'
        : 'low';
  const suggestedAction = [
    'approve',
    'admin_review',
    'reject',
    'escalate',
  ].includes(raw.suggestedAction)
    ? raw.suggestedAction
    : fallback.suggestedAction;

  return {
    approved: raw.approved === true && suggestedAction === 'approve',
    confidence: clamp01(raw.confidence || fallback.confidence),
    riskScore,
    riskLevel,
    suggestedAction,
    reasons: arrayOfStrings(raw.reasons),
    signals: arrayOfStrings(raw.signals),
    sellerHints: arrayOfStrings(raw.sellerHints),
  };
}

function outputText(responseBody) {
  if (typeof responseBody.output_text === 'string') return responseBody.output_text;
  const message = (responseBody.output || [])
    .flatMap((item) => item.content || [])
    .find((content) => content.type === 'output_text' && typeof content.text === 'string');
  return message ? message.text : '';
}

async function callOpenAiJson({ config, schema, developerText, userPayload, maxOutputTokens = 700 }) {
  const response = await fetch(OPENAI_RESPONSES_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: config.model,
      input: [
        {
          role: 'developer',
          content: [{ type: 'input_text', text: developerText }],
        },
        {
          role: 'user',
          content: [{ type: 'input_text', text: JSON.stringify(userPayload) }],
        },
      ],
      max_output_tokens: maxOutputTokens,
      text: { format: schema },
    }),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(body?.error?.message || `OpenAI request failed: ${response.status}`);
  }
  const text = outputText(body);
  if (!text) throw new Error('OpenAI response did not include output_text.');
  return JSON.parse(text);
}

async function callOpenAiForReview(payload, config) {
  const input = [
    {
      role: 'developer',
      content: [
        {
          type: 'input_text',
          text: [
            'You are the AI moderation and listing-quality layer for Olmeg Connect, a Firebase marketplace.',
            'Classify marketplace product listings. Human admins remain the authority for medium or high risk.',
            'Return only the requested JSON shape. Keep reasons factual and concise.',
          ].join(' '),
        },
      ],
    },
    {
      role: 'user',
      content: [
        {
          type: 'input_text',
          text: JSON.stringify({
            title: payload.title,
            description: payload.description,
            price: payload.price,
            category: payload.category,
            subcategory: payload.subcategory,
            location: payload.location,
            sellerSignals: payload.sellerSignals || {},
          }),
        },
      ],
    },
  ];

  if (payload.imageUrl && /^https?:|^data:image\//.test(payload.imageUrl)) {
    input[1].content.push({
      type: 'input_image',
      image_url: payload.imageUrl,
      detail: 'low',
    });
  }

  const response = await fetch(OPENAI_RESPONSES_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: config.model,
      input,
      max_output_tokens: 700,
      text: { format: REVIEW_SCHEMA },
    }),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(body?.error?.message || `OpenAI request failed: ${response.status}`);
  }

  const text = outputText(body);
  if (!text) {
    throw new Error('OpenAI response did not include output_text.');
  }
  return JSON.parse(text);
}

async function writeAiReview({ actorUid, productId, source, review, input }) {
  if (!productId) return null;
  const reviewRef = db.collection('ai_moderation_reviews').doc(productId);
  await reviewRef.set({
    productId,
    actorUid,
    source,
    title: input.title,
    category: input.category || null,
    riskScore: review.riskScore,
    riskLevel: review.riskLevel,
    suggestedAction: review.suggestedAction,
    approved: review.approved,
    confidence: review.confidence,
    reasons: review.reasons,
    signals: review.signals,
    sellerHints: review.sellerHints,
    provider: review.provider,
    model: review.model,
    schemaVersion: 1,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return reviewRef.id;
}

exports.analyzeProductWithAi = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }

  const title = requiredString(data?.title, 'title');
  const description = requiredString(data?.description, 'description');
  const price = Number(data?.price);
  const input = {
    productId: optionalString(data?.productId),
    title,
    description,
    price,
    category: optionalString(data?.category),
    subcategory: optionalString(data?.subcategory),
    location: optionalString(data?.location),
    imageUrl: optionalString(data?.imageUrl),
    sellerSignals: data?.sellerSignals && typeof data.sellerSignals === 'object'
      ? data.sellerSignals
      : {},
  };
  const fallback = heuristicReview(input);
  const config = openAiConfig();

  let review = fallback;
  if (config.apiKey) {
    try {
      const aiReview = await callOpenAiForReview(input, config);
      review = {
        ...normalizedReview(aiReview, fallback),
        provider: 'openai_responses',
        model: config.model,
      };
    } catch (error) {
      console.error('[AI] Product moderation fallback used', error.message);
      review = {
        ...fallback,
        reasons: fallback.reasons.length > 0
          ? fallback.reasons
          : ['AI review unavailable; local safety checks passed.'],
        signals: [...fallback.signals, 'openai_fallback'],
      };
    }
  }

  await writeAiReview({
    actorUid: context.auth.uid,
    productId: input.productId,
    source: 'seller_listing',
    review,
    input,
  });

  return {
    ok: true,
    productId: input.productId || null,
    review,
  };
});

exports.expandSearchWithAi = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }

  const query = requiredString(data?.query, 'query');
  const normalized = query.toLowerCase();
  const fallbackTerms = Array.from(new Set(
    normalized.split(/\s+/).filter(Boolean).concat([normalized]),
  )).slice(0, 12);
  const fallback = {
    normalizedQuery: normalized,
    expandedTerms: fallbackTerms,
    categoryHints: [],
    buyerIntent: 'browse',
    provider: 'local_rules',
    model: 'local_rules_v1',
  };
  const config = openAiConfig();
  if (!config.apiKey) return { ok: true, intent: fallback };

  try {
    const intent = await callOpenAiJson({
      config,
      schema: SEARCH_INTENT_SCHEMA,
      developerText: [
        'Expand marketplace search queries for product discovery.',
        'Include English and Arabic synonyms when useful.',
        'Do not invent product IDs or unsafe categories.',
      ].join(' '),
      userPayload: {
        query,
        locale: optionalString(data?.locale) || 'en',
      },
      maxOutputTokens: 400,
    });
    return {
      ok: true,
      intent: {
        normalizedQuery: optionalString(intent.normalizedQuery) || normalized,
        expandedTerms: arrayOfStrings(intent.expandedTerms).slice(0, 12),
        categoryHints: arrayOfStrings(intent.categoryHints).slice(0, 5),
        buyerIntent: optionalString(intent.buyerIntent) || 'browse',
        provider: 'openai_responses',
        model: config.model,
      },
    };
  } catch (error) {
    console.error('[AI] Search expansion fallback used', error.message);
    return { ok: true, intent: { ...fallback, signals: ['openai_fallback'] } };
  }
});

async function publicProductSummaries(limit = 80) {
  const snapshot = await db.collection('products')
    .orderBy('createdAt', 'desc')
    .limit(Math.min(Math.max(Number(limit || 80), 1), 100))
    .get();
  return snapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((item) => (
      item.status !== 'draft' &&
      item.status !== 'scheduled' &&
      item.publishStatus !== 'draft' &&
      item.publishStatus !== 'scheduled' &&
      (!item.moderationStatus || item.moderationStatus === 'approved')
    ))
    .map((item) => ({
      id: item.id,
      title: item.title || '',
      category: item.category || item.categoryName || '',
      subcategory: item.subCategoryName || item.subcategory || '',
      price: Number(item.price || 0),
      ratingAverage: Number(item.ratingAverage || 0),
      discountPercent: Number(item.discountPercent || 0),
      inStock: item.stock !== 0 && item.stockQuantity !== 0,
      createdAt: item.createdAt || null,
    }));
}

function fallbackRecommendationIds(products, signalProductIds) {
  const seen = new Set(signalProductIds || []);
  return products
    .filter((product) => !seen.has(product.id))
    .sort((a, b) => {
      const stock = Number(b.inStock) - Number(a.inStock);
      if (stock !== 0) return stock;
      const rating = b.ratingAverage - a.ratingAverage;
      if (rating !== 0) return rating;
      return b.discountPercent - a.discountPercent;
    })
    .slice(0, 12)
    .map((product) => product.id);
}

exports.getBuyerRecommendationsWithAi = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }

  const signalProductIds = arrayOfStrings(data?.signalProductIds).slice(0, 30);
  const products = await publicProductSummaries(100);
  const fallbackIds = fallbackRecommendationIds(products, signalProductIds);
  const config = openAiConfig();
  if (!config.apiKey) {
    return {
      ok: true,
      productIds: fallbackIds,
      explanation: 'Ranked by availability, rating, and current deals.',
      provider: 'local_rules',
      model: 'local_rules_v1',
    };
  }

  try {
    const result = await callOpenAiJson({
      config,
      schema: RECOMMENDATION_SCHEMA,
      developerText: [
        'Rank product IDs for a marketplace buyer.',
        'Use only IDs present in candidateProducts.',
        'Prefer relevant, available, trusted, and varied results.',
      ].join(' '),
      userPayload: {
        signalProductIds,
        candidateProducts: products,
      },
      maxOutputTokens: 500,
    });
    const allowed = new Set(products.map((product) => product.id));
    const productIds = arrayOfStrings(result.productIds)
      .filter((id) => allowed.has(id))
      .slice(0, 12);
    return {
      ok: true,
      productIds: productIds.length > 0 ? productIds : fallbackIds,
      explanation: optionalString(result.explanation) || 'Personalized from marketplace signals.',
      provider: 'openai_responses',
      model: config.model,
    };
  } catch (error) {
    console.error('[AI] Recommendation fallback used', error.message);
    return {
      ok: true,
      productIds: fallbackIds,
      explanation: 'AI ranking unavailable; using local marketplace ranking.',
      provider: 'local_rules',
      model: 'local_rules_v1',
    };
  }
});

exports.getSellerListingHintsWithAi = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }

  const input = {
    title: requiredString(data?.title, 'title'),
    description: requiredString(data?.description, 'description'),
    price: Number(data?.price || 0),
    category: optionalString(data?.category),
    subcategory: optionalString(data?.subcategory),
    location: optionalString(data?.location),
  };
  const fallback = {
    titleSuggestions: ['Mention brand, product type, condition, and key model details.'],
    descriptionSuggestions: [
      'Describe condition, included accessories, defects, pickup or delivery options, and warranty.',
    ],
    pricingSignals: ['Compare against similar listings before publishing.'],
    trustSignals: ['Add clear photos and honest condition notes.'],
    provider: 'local_rules',
    model: 'local_rules_v1',
  };
  const config = openAiConfig();
  if (!config.apiKey) return { ok: true, hints: fallback };

  try {
    const hints = await callOpenAiJson({
      config,
      schema: SELLER_HINTS_SCHEMA,
      developerText: [
        'Give seller optimization hints for a marketplace listing.',
        'Keep suggestions practical, short, and policy-safe.',
        'Do not promise sale outcomes.',
      ].join(' '),
      userPayload: input,
      maxOutputTokens: 500,
    });
    return {
      ok: true,
      hints: {
        titleSuggestions: arrayOfStrings(hints.titleSuggestions).slice(0, 3),
        descriptionSuggestions: arrayOfStrings(hints.descriptionSuggestions).slice(0, 5),
        pricingSignals: arrayOfStrings(hints.pricingSignals).slice(0, 4),
        trustSignals: arrayOfStrings(hints.trustSignals).slice(0, 4),
        provider: 'openai_responses',
        model: config.model,
      },
    };
  } catch (error) {
    console.error('[AI] Seller hints fallback used', error.message);
    return { ok: true, hints: fallback };
  }
});

function roleFromContext(context) {
  const token = context.auth && context.auth.token;
  if (!token) return null;
  if (token.role) return token.role;
  if (Array.isArray(token.roles) && token.roles.length > 0) return token.roles[0];
  if (token.admin === true) return 'admin';
  return null;
}

function assertAdminAssistantAllowed(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }
  const role = roleFromContext(context);
  if (!['support', 'moderator', 'admin', 'super_admin'].includes(role)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'This admin role cannot use the assistant.',
    );
  }
  return { uid: context.auth.uid, role };
}

async function adminQueueSnapshot() {
  const sources = [
    'product_submissions',
    'reports',
    'support_tickets',
    'risk_cases',
    'orders',
    'payments',
    'refunds',
  ];
  const result = {};
  for (const source of sources) {
    const snapshot = await db.collection(source).limit(10).get();
    result[source] = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        status: data.status || data.moderationStatus || null,
        priority: data.priority || data.severity || data.aiRiskLevel || null,
        title: data.title || data.subject || data.reason || null,
        updatedAt: data.updatedAt || data.createdAt || null,
      };
    });
  }
  return result;
}

exports.adminAskAssistantWithAi = functions.https.onCall(async (data, context) => {
  const actor = assertAdminAssistantAllowed(context);
  const question = requiredString(data?.question, 'question');
  const snapshot = await adminQueueSnapshot();
  const fallback = {
    summary: 'Review the capped queue snapshot and prioritize high-risk or customer-blocking records first.',
    nextActions: [
      'Open escalated moderation and risk cases.',
      'Check support tickets and refunds with stale status.',
      'Use backend commands for sensitive changes.',
    ],
    risks: ['Assistant output is advisory; staff actions still require role checks and audit logs.'],
    collectionsToInspect: Object.keys(snapshot),
    provider: 'local_rules',
    model: 'local_rules_v1',
  };
  const config = openAiConfig();
  let answer = fallback;

  if (config.apiKey) {
    try {
      const aiAnswer = await callOpenAiJson({
        config,
        schema: ADMIN_ASSISTANT_SCHEMA,
        developerText: [
          'You assist marketplace operations staff.',
          'Use only the provided capped queue snapshot.',
          'Never tell staff to bypass Firebase Rules, Custom Claims, callable commands, or audit logs.',
        ].join(' '),
        userPayload: { question, queues: snapshot, actorRole: actor.role },
        maxOutputTokens: 700,
      });
      answer = {
        summary: optionalString(aiAnswer.summary) || fallback.summary,
        nextActions: arrayOfStrings(aiAnswer.nextActions).slice(0, 6),
        risks: arrayOfStrings(aiAnswer.risks).slice(0, 6),
        collectionsToInspect: arrayOfStrings(aiAnswer.collectionsToInspect).slice(0, 8),
        provider: 'openai_responses',
        model: config.model,
      };
    } catch (error) {
      console.error('[AI] Admin assistant fallback used', error.message);
    }
  }

  await db.collection('audit_logs').doc().set({
    actorUid: actor.uid,
    actorRole: actor.role,
    action: 'admin_ai_assistant_asked',
    targetType: 'ai_assistant',
    targetId: 'admin_operations',
    metadata: {
      questionLength: question.length,
      provider: answer.provider,
      collectionsToInspect: answer.collectionsToInspect,
    },
    schemaVersion: 1,
    immutable: true,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { ok: true, answer };
});
