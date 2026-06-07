/**
 * Firebase Cloud Functions for Olmeg Connect
 * 
 * Features:
 * 1. Admin Manual Notifications - Send to all users, specific user, or topic
 * 2. Automated Notifications - New post, new message, new rating, product sold
 * 
 * Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
admin.initializeApp();
const adminCommands = require('./adminCommands');
const aiServices = require('./aiServices');

Object.assign(exports, adminCommands);
Object.assign(exports, aiServices);

// Firestore reference
const db = admin.firestore();

// Collection references
const USERS_COLLECTION = 'users';
const NOTIFICATIONS_COLLECTION = 'notifications';
const ADMIN_NOTIFICATIONS_COLLECTION = 'admin_notifications';
const POSTS_COLLECTION = 'posts';
const CHATS_COLLECTION = 'chats';
const RATINGS_COLLECTION = 'ratings';
const PAYMENTS_COLLECTION = 'payments';
const ORDERS_COLLECTION = 'orders';
const PAYMOB_WEBHOOKS_COLLECTION = 'paymob_webhooks';
const PAYMENT_RECONCILIATIONS_COLLECTION = 'payment_reconciliations';
const AUDIT_LOGS_COLLECTION = 'audit_logs';

function requireAdminCaller(context) {
  const token = context.auth && context.auth.token;
  const role = token?.role;
  const roles = Array.isArray(token?.roles) ? token.roles : [];
  const allowed = token?.admin === true ||
    role === 'admin' ||
    role === 'super_admin' ||
    roles.includes('admin') ||
    roles.includes('super_admin');

  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }
  if (!allowed) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin privileges are required.',
    );
  }
  return { uid: context.auth.uid, role: role || (token?.admin === true ? 'admin' : 'user') };
}

function paymobConfig() {
  const runtimeConfig = functions.config().paymob || {};
  const baseUrl = process.env.PAYMOB_BASE_URL ||
    runtimeConfig.base_url ||
    'https://accept.paymob.com';
  const publicKey = process.env.PAYMOB_PUBLIC_KEY || runtimeConfig.public_key;
  const secretKey = process.env.PAYMOB_SECRET_KEY || runtimeConfig.secret_key;
  const hmacSecret = process.env.PAYMOB_HMAC_SECRET || runtimeConfig.hmac_secret;
  const integrationIdsRaw =
    process.env.PAYMOB_INTEGRATION_IDS || runtimeConfig.integration_ids || '';
  const integrationIds = integrationIdsRaw
    .split(',')
    .map((value) => Number(value.trim()))
    .filter((value) => Number.isFinite(value));

  return {
    baseUrl: baseUrl.replace(/\/$/, ''),
    publicKey,
    secretKey,
    hmacSecret,
    integrationIds,
    webhookUrl: process.env.PAYMOB_WEBHOOK_URL || runtimeConfig.webhook_url,
    redirectUrl: process.env.PAYMOB_REDIRECT_URL || runtimeConfig.redirect_url,
  };
}

function requirePaymobConfig(config) {
  const missing = [];
  if (!config.publicKey) missing.push('PAYMOB_PUBLIC_KEY');
  if (!config.secretKey) missing.push('PAYMOB_SECRET_KEY');
  if (config.integrationIds.length === 0) missing.push('PAYMOB_INTEGRATION_IDS');
  if (missing.length > 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Missing Paymob configuration: ${missing.join(', ')}`
    );
  }
}

function amountToCents(amount) {
  return Math.round(Number(amount || 0) * 100);
}

function splitFullName(fullName) {
  const parts = String(fullName || 'Olmeg Customer').trim().split(/\s+/);
  return {
    firstName: parts[0] || 'Olmeg',
    lastName: parts.slice(1).join(' ') || 'Customer',
  };
}

function countryCode(value) {
  const normalized = String(value || '').trim().toLowerCase();
  if (!normalized || normalized === 'egypt') return 'EG';
  return String(value).trim();
}

function buildCheckoutUrl(config, clientSecret) {
  const params = new URLSearchParams({
    publicKey: config.publicKey,
    clientSecret,
  });
  return `${config.baseUrl}/unifiedcheckout/?${params.toString()}`;
}

function paymobBillingData(order, userData) {
  const shipping = order.shippingAddress || {};
  const name = splitFullName(shipping.fullName || userData?.name);
  return {
    first_name: name.firstName,
    last_name: name.lastName,
    email: userData?.email || 'customer@olmeg-connect.local',
    phone_number: shipping.phone || userData?.phone || '01000000000',
    country: countryCode(shipping.country),
    city: shipping.city || 'Cairo',
    state: shipping.region || shipping.city || 'Cairo',
    postal_code: shipping.postalCode || '00000',
    street: shipping.line1 || 'N/A',
    apartment: shipping.line2 || 'N/A',
    building: 'N/A',
    floor: 'N/A',
  };
}

function paymobItems(order) {
  const items = Array.isArray(order.items) ? order.items : [];
  return items.map((item) => ({
    name: item.titleSnapshot || item.productId || 'Olmeg item',
    amount: amountToCents(item.lineTotal || item.unitPrice || 0),
    description: item.productId || 'Olmeg marketplace item',
    quantity: Number(item.quantity || 1),
  }));
}

function productCheckoutPrice(product) {
  const basePrice = Number(product.price || 0);
  const salePrice = Number(product.salePriceOverride);
  return Number.isFinite(salePrice) && salePrice > 0 ? salePrice : basePrice;
}

function isPublicCheckoutProduct(product) {
  return product.status === 'active' ||
    product.moderationStatus === 'approved' ||
    product.publishStatus === 'published';
}

async function verifiedCheckoutOrder(order) {
  const items = Array.isArray(order.items) ? order.items : [];
  if (items.length === 0 || items.length > 100) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Order must contain at least one valid item.'
    );
  }

  const productIds = [...new Set(items.map((item) => String(item.productId || '').trim()))];
  if (productIds.some((id) => !id)) {
    throw new functions.https.HttpsError('invalid-argument', 'Every order item needs a productId.');
  }

  const productSnaps = await Promise.all(
    productIds.map((id) => db.collection('products').doc(id).get())
  );
  const products = new Map();
  productSnaps.forEach((snap) => {
    if (snap.exists) products.set(snap.id, snap.data() || {});
  });

  let expectedSubtotal = 0;
  const sellerIds = new Set();
  const verifiedItems = items.map((item) => {
    const productId = String(item.productId || '').trim();
    const product = products.get(productId);
    const quantity = Number(item.quantity || 0);
    if (!product) {
      throw new functions.https.HttpsError('failed-precondition', 'Product is no longer available.');
    }
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid item quantity.');
    }
    if (!isPublicCheckoutProduct(product)) {
      throw new functions.https.HttpsError('failed-precondition', 'Product is not available for checkout.');
    }
    const sellerId = String(product.sellerId || '');
    const unitPrice = productCheckoutPrice(product);
    if (!sellerId || !Number.isFinite(unitPrice) || unitPrice <= 0) {
      throw new functions.https.HttpsError('failed-precondition', 'Product cannot be priced for checkout.');
    }

    sellerIds.add(sellerId);
    const lineTotal = unitPrice * quantity;
    expectedSubtotal += lineTotal;
    return {
      ...item,
      productId,
      sellerId,
      titleSnapshot: product.title || item.titleSnapshot || productId,
      imageUrlSnapshot: product.imageUrl || item.imageUrlSnapshot || null,
      quantity,
      unitPrice,
      lineTotal,
    };
  });

  const claimedTotal = Number(order.total || 0);
  if (!Number.isFinite(claimedTotal) || claimedTotal + 0.01 < expectedSubtotal) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Order total does not match current product pricing.'
    );
  }

  return {
    ...order,
    items: verifiedItems,
    sellerIds: [...sellerIds],
    subtotal: expectedSubtotal,
    total: claimedTotal,
  };
}

async function createPaymobIntention(orderId, order, userData, config) {
  const amountCents = amountToCents(order.total);
  if (amountCents <= 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Order total must be greater than zero before starting Paymob checkout.'
    );
  }

  const payload = {
    amount: amountCents,
    currency: checkoutOrder.currency || 'EGP',
    payment_methods: config.integrationIds,
    billing_data: paymobBillingData(order, userData),
    items: paymobItems(order),
    special_reference: orderId,
    extras: {
      orderId,
      buyerId: order.buyerId,
      merchant_intention_id: orderId,
    },
  };

  if (config.webhookUrl) payload.notification_url = config.webhookUrl;
  if (config.redirectUrl) payload.redirection_url = config.redirectUrl;

  const response = await fetch(`${config.baseUrl}/v1/intention/`, {
    method: 'POST',
    headers: {
      Authorization: `Token ${config.secretKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    console.error('[Paymob] Intention failed', response.status, body);
    throw new functions.https.HttpsError(
      'internal',
      body?.detail || body?.message || 'Paymob intention creation failed.'
    );
  }

  const clientSecret = body.client_secret || body.cs || body.clientSecret;
  if (!clientSecret) {
    console.error('[Paymob] Missing client_secret', body);
    throw new functions.https.HttpsError(
      'internal',
      'Paymob did not return a client secret.'
    );
  }

  return {
    body: {
      ...body,
      client_secret: clientSecret,
    },
    amountCents,
    checkoutUrl: buildCheckoutUrl(config, clientSecret),
  };
}

exports.createPaymobPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');
  }

  const orderId = String(data?.orderId || '').trim();
  if (!orderId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'orderId is required.'
    );
  }

  const config = paymobConfig();
  requirePaymobConfig(config);

  const orderRef = db.collection(ORDERS_COLLECTION).doc(orderId);
  const paymentRef = db.collection(PAYMENTS_COLLECTION).doc(orderId);
  const userRef = db.collection(USERS_COLLECTION).doc(context.auth.uid);

  const [orderSnap, paymentSnap, userSnap] = await Promise.all([
    orderRef.get(),
    paymentRef.get(),
    userRef.get(),
  ]);

  if (!orderSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Order not found.');
  }

  const order = orderSnap.data();
  if (order.buyerId !== context.auth.uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only the buyer can start payment for this order.'
    );
  }

  const checkoutOrder = await verifiedCheckoutOrder(order);

  if (paymentSnap.exists) {
    const existing = paymentSnap.data();
    if (existing.status === 'pending' && existing.paymobClientSecret) {
      if (Number(existing.amount || 0) + 0.01 < checkoutOrder.subtotal) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Existing payment does not match current product pricing.'
        );
      }
      return {
        orderId,
        paymentId: paymentRef.id,
        clientSecret: existing.paymobClientSecret,
        publicKey: config.publicKey,
        checkoutUrl: existing.checkoutUrl,
        status: existing.status,
      };
    }
  }

  const userData = userSnap.exists ? userSnap.data() : {};
  const intention = await createPaymobIntention(orderId, checkoutOrder, userData, config);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const paymobBody = intention.body;
  const paymobIntentionId = String(paymobBody.id || paymobBody.intention_id || '');
  const paymobOrderId = paymobBody.order?.id || paymobBody.order_id || null;

  const batch = db.batch();
  batch.set(paymentRef, {
    id: paymentRef.id,
    orderId,
    userId: context.auth.uid,
    buyerId: context.auth.uid,
    sellerIds: checkoutOrder.sellerIds || [],
    amount: Number(checkoutOrder.total || 0),
    amountCents: intention.amountCents,
    currency: checkoutOrder.currency || 'EGP',
    status: 'pending',
    paymentMethod: 'paymob',
    provider: 'paymob',
    paymobIntentionId,
    paymobOrderId,
    paymobClientSecret: paymobBody.client_secret,
    checkoutUrl: intention.checkoutUrl,
    createdAt: now,
    updatedAt: now,
  }, { merge: true });
  batch.update(orderRef, {
    items: checkoutOrder.items,
    sellerIds: checkoutOrder.sellerIds,
    subtotal: checkoutOrder.subtotal,
    total: checkoutOrder.total,
    'payment.provider': 'paymob',
    'payment.providerPaymentId': paymobIntentionId || paymentRef.id,
    'payment.status': 'pending',
    'payment.failureReason': null,
    updatedAt: now,
  });
  batch.create(db.collection(AUDIT_LOGS_COLLECTION).doc(), {
    actorUid: context.auth.uid,
    actorRole: context.auth.token?.role || 'user',
    action: 'paymob_payment_intention_created',
    targetType: 'payment',
    targetId: paymentRef.id,
    metadata: {
      orderId,
      amountCents: intention.amountCents,
      currency: checkoutOrder.currency || 'EGP',
      paymobIntentionId,
    },
    schemaVersion: 1,
    immutable: true,
    createdAt: now,
  });
  batch.set(db.collection(PAYMENT_RECONCILIATIONS_COLLECTION).doc(paymentRef.id), {
    paymentId: paymentRef.id,
    orderId,
    provider: 'paymob',
    status: 'intention_created',
    amountCents: intention.amountCents,
    currency: order.currency || 'EGP',
    paymobIntentionId,
    paymobOrderId,
    lastEventAt: now,
    updatedAt: now,
  }, { merge: true });

  await batch.commit();

  return {
    orderId,
    paymentId: paymentRef.id,
    clientSecret: paymobBody.client_secret,
    publicKey: config.publicKey,
    checkoutUrl: intention.checkoutUrl,
    status: 'pending',
  };
});

function paymobValue(obj, path) {
  return path.split('.').reduce((current, key) => {
    if (current == null) return undefined;
    return current[key];
  }, obj);
}

function normalizePaymobValue(value) {
  if (value === true) return 'true';
  if (value === false) return 'false';
  if (value == null) return '';
  return String(value);
}

function verifyPaymobHmac(obj, receivedHmac, hmacSecret) {
  if (!receivedHmac || !hmacSecret) return false;
  const hmacPaths = [
    'amount_cents',
    'created_at',
    'currency',
    'error_occured',
    'has_parent_transaction',
    'id',
    'integration_id',
    'is_3d_secure',
    'is_auth',
    'is_capture',
    'is_refunded',
    'is_standalone_payment',
    'is_voided',
    'order.id',
    'owner',
    'pending',
    'source_data.pan',
    'source_data.sub_type',
    'source_data.type',
    'success',
  ];
  const message = hmacPaths
    .map((path) => normalizePaymobValue(paymobValue(obj, path)))
    .join('');
  const expected = crypto
    .createHmac('sha512', hmacSecret)
    .update(message)
    .digest('hex');
  const expectedBuffer = Buffer.from(expected);
  const receivedBuffer = Buffer.from(String(receivedHmac));
  if (expectedBuffer.length !== receivedBuffer.length) return false;
  return crypto.timingSafeEqual(expectedBuffer, receivedBuffer);
}

function boolValue(value) {
  return value === true || value === 'true';
}

function paymobPaymentStatus(obj) {
  if (boolValue(obj.is_refunded)) return 'refunded';
  if (boolValue(obj.is_voided)) return 'voided';
  if (boolValue(obj.success)) return 'completed';
  if (boolValue(obj.pending)) return 'pending';
  return 'failed';
}

function orderPaymentStatus(paymentStatus) {
  if (paymentStatus === 'completed') return 'paid';
  if (paymentStatus === 'failed') return 'failed';
  if (paymentStatus === 'refunded') return 'refunded';
  return 'pending';
}

function orderStatusFromPayment(paymentStatus) {
  if (paymentStatus === 'refunded') return 'refunded';
  return paymentStatus === 'completed' ? 'paid' : 'pendingPayment';
}

function localOrderIdFromPaymob(obj) {
  return obj.special_reference ||
    obj.merchant_order_id ||
    obj.order?.merchant_order_id ||
    obj.payment_key_claims?.extra?.orderId ||
    obj.extra?.orderId ||
    null;
}

async function paymentRefForPaymobCallback(obj) {
  const localOrderId = localOrderIdFromPaymob(obj);
  if (localOrderId) {
    return db.collection(PAYMENTS_COLLECTION).doc(String(localOrderId));
  }

  const paymobOrderId = obj.order?.id == null ? null : String(obj.order.id);
  if (paymobOrderId) {
    const snap = await db.collection(PAYMENTS_COLLECTION)
      .where('paymobOrderId', '==', paymobOrderId)
      .limit(1)
      .get();
    if (!snap.empty) return snap.docs[0].ref;
  }

  const intentionId = obj.payment_key_claims?.intention_id || obj.intention_id;
  if (intentionId) {
    const snap = await db.collection(PAYMENTS_COLLECTION)
      .where('paymobIntentionId', '==', String(intentionId))
      .limit(1)
      .get();
    if (!snap.empty) return snap.docs[0].ref;
  }

  return null;
}

exports.paymobWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST' && req.method !== 'GET') {
    res.status(405).send('Method not allowed');
    return;
  }

  const config = paymobConfig();
  const payload = req.method === 'GET' ? req.query : req.body;
  const obj = payload?.obj || payload;
  const receivedHmac = req.query?.hmac || payload?.hmac;

  if (!verifyPaymobHmac(obj, receivedHmac, config.hmacSecret)) {
    console.warn('[PaymobWebhook] Invalid HMAC');
    res.status(401).send('Invalid HMAC');
    return;
  }

  const transactionId = String(obj.id || obj.transaction_id || crypto
    .createHash('sha256')
    .update(JSON.stringify(obj))
    .digest('hex'));
  const webhookRef = db.collection(PAYMOB_WEBHOOKS_COLLECTION)
    .doc(`paymob_${transactionId}`);

  try {
    await webhookRef.create({
      transactionId,
      status: 'received',
      payload: obj,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    if (error.code === 6 || error.code === 'already-exists') {
      res.status(200).json({ received: true, duplicate: true });
      return;
    }
    throw error;
  }

  const paymentRef = await paymentRefForPaymobCallback(obj);
  if (!paymentRef) {
    await webhookRef.update({
      status: 'unmatched',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await db.collection(PAYMENT_RECONCILIATIONS_COLLECTION)
      .doc(`unmatched_${transactionId}`)
      .set({
        provider: 'paymob',
        status: 'unmatched',
        transactionId,
        payload: obj,
        lastEventAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    res.status(202).json({ received: true, status: 'unmatched' });
    return;
  }

  const paymentSnap = await paymentRef.get();
  if (!paymentSnap.exists) {
    await webhookRef.update({
      status: 'unmatched',
      unmatchedReason: 'payment_record_not_found',
      paymentId: paymentRef.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await db.collection(PAYMENT_RECONCILIATIONS_COLLECTION)
      .doc(`unmatched_${transactionId}`)
      .set({
        provider: 'paymob',
        status: 'unmatched',
        reason: 'payment_record_not_found',
        localPaymentId: paymentRef.id,
        transactionId,
        payload: obj,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    res.status(202).send('Payment record not found');
    return;
  }

  const payment = paymentSnap.data() || {};
  const orderRef = db.collection(ORDERS_COLLECTION).doc(payment.orderId || paymentRef.id);
  const paymentStatus = paymobPaymentStatus(obj);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const failureReason = paymentStatus === 'failed'
    ? (obj.data?.message || obj.txn_response_code || 'Paymob payment failed')
    : null;

  const batch = db.batch();
  batch.set(paymentRef, {
    status: paymentStatus,
    paymobTransactionId: transactionId,
    paymobOrderId: obj.order?.id || payment.paymobOrderId || null,
    rawStatus: {
      success: obj.success,
      pending: obj.pending,
      error_occured: obj.error_occured,
      txn_response_code: obj.txn_response_code || null,
    },
    completedAt: paymentStatus === 'completed' ? now : null,
    updatedAt: now,
  }, { merge: true });
  batch.set(orderRef, {
    payment: {
      provider: 'paymob',
      providerPaymentId: transactionId,
      status: orderPaymentStatus(paymentStatus),
      paidAt: paymentStatus === 'completed' ? now : null,
      failureReason,
    },
    status: orderStatusFromPayment(paymentStatus),
    updatedAt: now,
  }, { merge: true });
  batch.update(webhookRef, {
    status: 'processed',
    paymentId: paymentRef.id,
    orderId: payment.orderId || paymentRef.id,
    updatedAt: now,
  });
  batch.set(db.collection(PAYMENT_RECONCILIATIONS_COLLECTION).doc(paymentRef.id), {
    paymentId: paymentRef.id,
    orderId: payment.orderId || paymentRef.id,
    provider: 'paymob',
    status: paymentStatus,
    transactionId,
    amountCents: obj.amount_cents || payment.amountCents || null,
    currency: obj.currency || payment.currency || 'EGP',
    paymobOrderId: obj.order?.id || payment.paymobOrderId || null,
    lastWebhookId: webhookRef.id,
    lastEventAt: now,
    updatedAt: now,
  }, { merge: true });
  batch.create(db.collection(AUDIT_LOGS_COLLECTION).doc(), {
    actorUid: 'paymob_webhook',
    actorRole: 'system',
    action: 'paymob_payment_status_webhook',
    targetType: 'payment',
    targetId: paymentRef.id,
    metadata: {
      orderId: payment.orderId || paymentRef.id,
      paymentStatus,
      transactionId,
    },
    schemaVersion: 1,
    immutable: true,
    createdAt: now,
  });

  await batch.commit();
  res.status(200).json({ received: true, status: paymentStatus });
});

// ============================================================================
// ADMIN MANUAL NOTIFICATIONS
// ============================================================================

/**
 * Trigger: When a new admin notification is created
 * Action: Send push notification to target users
 */
exports.sendAdminNotification = functions.firestore
  .document(`${ADMIN_NOTIFICATIONS_COLLECTION}/{notificationId}`)
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const notificationId = context.params.notificationId;

    console.log('[AdminNotification] Processing notification:', notificationId);

    try {
      // Get the notification data
      const { title, body, target, targetId, topic } = notificationData;

      if (notificationData.source === 'admin_command') {
        console.log('[AdminNotification] Skipping command-managed campaign:', notificationId);
        return;
      }

      if (!title || !body) {
        console.error('[AdminNotification] Missing title or body');
        await snap.ref.update({ status: 'failed', error: 'Missing title or body' });
        return;
      }

      let tokens = [];

      // Determine target and get FCM tokens
      if (target === 'all') {
        // Get all users' tokens
        tokens = await getAllUserTokens();
      } else if (target === 'userId' && targetId) {
        // Get specific user's token
        const token = await getUserToken(targetId);
        if (token) tokens = [token];
      } else if (target === 'topic' && topic) {
        // Topic-based notification - handled by FCM topic messaging
        await sendTopicNotification(topic, title, body, notificationData);
        await snap.ref.update({ status: 'sent', sentAt: admin.firestore.FieldValue.serverTimestamp() });
        console.log('[AdminNotification] Topic notification sent:', topic);
        return;
      }

      if (tokens.length === 0) {
        console.log('[AdminNotification] No tokens found for target:', target);
        await snap.ref.update({ status: 'no_tokens', sentAt: admin.firestore.FieldValue.serverTimestamp() });
        return;
      }

      // Send notifications in batches (max 500 per batch)
      const batches = [];
      for (let i = 0; i < tokens.length; i += 500) {
        batches.push(tokens.slice(i, i + 500));
      }

      let sentCount = 0;
      let failedCount = 0;

      for (const tokenBatch of batches) {
        try {
          const response = await admin.messaging().sendEachForMulticast({
            tokens: tokenBatch,
            notification: {
              title: title,
              body: body,
            },
            data: {
              type: 'manual',
              notificationId: notificationId,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              priority: 'high',
              notification: {
                channel_id: 'olmeg_connect_channel',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                },
              },
            },
          });

          sentCount += response.successCount;
          failedCount += response.failureCount;

          // Handle failed tokens
          if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
              if (!resp.success) {
                console.log('[AdminNotification] Token error:', resp.error?.message);
                failedTokens.push(tokenBatch[idx]);
              }
            });

            // Remove invalid tokens
            if (failedTokens.length > 0) {
              await removeInvalidTokens(failedTokens);
            }
          }
        } catch (error) {
          console.error('[AdminNotification] Batch send error:', error);
          failedCount += tokenBatch.length;
        }
      }

      // Update notification status
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        sentCount: sentCount,
        failedCount: failedCount,
      });

      console.log(`[AdminNotification] Sent: ${sentCount}, Failed: ${failedCount}`);

    } catch (error) {
      console.error('[AdminNotification] Error:', error);
      await snap.ref.update({
        status: 'error',
        error: error.message,
      });
    }
  });

// ============================================================================
// AUTOMATED NOTIFICATIONS - NEW POST
// ============================================================================

/**
 * Trigger: When a new post is created
 * Action: Notify followers or all users based on post type
 */
exports.notifyNewPost = functions.firestore
  .document(`${POSTS_COLLECTION}/{postId}`)
  .onCreate(async (snap, context) => {
    const post = snap.data();
    const postId = context.params.postId;

    console.log('[NewPost] Processing post:', postId);

    try {
      const { authorId, authorName, postType, title, category } = post;

      // Determine notification title and body based on post type
      let notificationTitle, notificationBody;

      if (postType === 'made') {
        notificationTitle = `🛒 ${authorName} has a new product for sale!`;
        notificationBody = title || `Check out the new listing in ${category || 'marketplace'}`;
      } else if (postType === 'wanted') {
        notificationTitle = `🔍 ${authorName} is looking for something`;
        notificationBody = title || `See what they need in ${category || 'marketplace'}`;
      } else {
        notificationTitle = `📝 New post from ${authorName}`;
        notificationBody = title || 'Check out the new post';
      }

      // Get all users except the author
      const tokens = await getAllUserTokensExcept(authorId);

      if (tokens.length === 0) {
        console.log('[NewPost] No tokens to notify');
        return;
      }

      // Send notifications
      await sendBatchNotifications(tokens, {
        title: notificationTitle,
        body: notificationBody,
        data: {
          type: 'new_post',
          postId: postId,
          authorId: authorId,
          postType: postType || 'general',
        },
      });

      console.log(`[NewPost] Notified ${tokens.length} users`);

    } catch (error) {
      console.error('[NewPost] Error:', error);
    }
  });

// ============================================================================
// AUTOMATED NOTIFICATIONS - NEW MESSAGE
// ============================================================================

/**
 * Trigger: When a new message is added to a chat
 * Action: Notify the recipient
 */
exports.notifyNewMessage = functions.firestore
  .document(`${CHATS_COLLECTION}/{chatId}/messages/{messageId}`)
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { chatId, messageId } = context.params;

    console.log('[NewMessage] Processing message:', messageId);

    try {
      const { senderId, senderName, text } = message;

      // Get chat participants
      const chatDoc = await db.collection(CHATS_COLLECTION).doc(chatId).get();
      if (!chatDoc.exists) {
        console.log('[NewMessage] Chat not found');
        return;
      }

      const chatData = chatDoc.data();
      const participants = chatData?.participants || [];

      // Find recipient (not the sender)
      const recipientId = participants.find(id => id !== senderId);

      if (!recipientId) {
        console.log('[NewMessage] No recipient found');
        return;
      }

      // Get recipient's token
      const token = await getUserToken(recipientId);

      if (!token) {
        console.log('[NewMessage] No token for recipient');
        return;
      }

      // Send notification
      await admin.messaging().send({
        token: token,
        notification: {
          title: `💬 New message from ${senderName}`,
          body: text?.substring(0, 100) || 'You have a new message',
        },
        data: {
          type: 'new_message',
          chatId: chatId,
          messageId: messageId,
          senderId: senderId,
        },
        android: {
          priority: 'high',
        },
      });

      // Also create in-app notification
      await db.collection(NOTIFICATIONS_COLLECTION).add({
        userId: recipientId,
        type: 'message',
        title: `New message from ${senderName}`,
        message: text?.substring(0, 200) || 'You have a new message',
        relatedId: chatId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log('[NewMessage] Notification sent');

    } catch (error) {
      console.error('[NewMessage] Error:', error);
    }
  });

// ============================================================================
// AUTOMATED NOTIFICATIONS - NEW RATING
// ============================================================================

/**
 * Trigger: When a new rating is created
 * Action: Notify the seller
 */
exports.notifyNewRating = functions.firestore
  .document(`${RATINGS_COLLECTION}/{ratingId}`)
  .onCreate(async (snap, context) => {
    const rating = snap.data();
    const ratingId = context.params.ratingId;

    console.log('[NewRating] Processing rating:', ratingId);

    try {
      const { sellerId, buyerId, buyerName, rating: ratingValue, review } = rating;

      // Get seller's token
      const token = await getUserToken(sellerId);

      if (!token) {
        console.log('[NewRating] No token for seller');
        return;
      }

      // Create star representation
      const stars = '⭐' * ratingValue;

      // Send notification
      await admin.messaging().send({
        token: token,
        notification: {
          title: `${stars} New ${ratingValue}-star rating!`,
          body: review 
            ? `${buyerName} said: "${review.substring(0, 100)}"`
            : `${buyerName} rated your profile`,
        },
        data: {
          type: 'new_rating',
          ratingId: ratingId,
          buyerId: buyerId,
        },
      });

      // Also create in-app notification
      await db.collection(NOTIFICATIONS_COLLECTION).add({
        userId: sellerId,
        type: 'rating',
        title: `${stars} New ${ratingValue}-star rating!`,
        message: review 
          ? `${buyerName} said: "${review.substring(0, 200)}"`
          : `${buyerName} rated your profile`,
        relatedId: ratingId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log('[NewRating] Notification sent to seller');

    } catch (error) {
      console.error('[NewRating] Error:', error);
    }
  });

// ============================================================================
// AUTOMATED NOTIFICATIONS - PRODUCT SOLD
// ============================================================================

/**
 * Trigger: When a payment is completed
 * Action: Notify both buyer and seller
 */
exports.notifyPaymentCompleted = functions.firestore
  .document(`${PAYMENTS_COLLECTION}/{paymentId}`)
  .onUpdate(async (change, context) => {
    const paymentId = context.params.paymentId;
    const before = change.before.data();
    const after = change.after.data();

    console.log('[PaymentCompleted] Processing payment:', paymentId);

    // Only trigger on status change to completed
    if (before?.status === 'completed' || after?.status !== 'completed') {
      console.log('[PaymentCompleted] No status change to completed');
      return;
    }

    try {
      const buyerId = after.buyerId || after.userId;
      const sellerIds = Array.isArray(after.sellerIds)
        ? after.sellerIds
        : [after.sellerId].filter(Boolean);
      const { productId, amount, orderId } = after;

      // Notify seller
      for (const sellerId of sellerIds) {
        const sellerToken = await getUserToken(sellerId);
        if (!sellerToken) continue;
        await admin.messaging().send({
          token: sellerToken,
          notification: {
            title: '💰 Payment Received!',
            body: `You received \$${amount} for your product`,
          },
          data: {
            type: 'payment_received',
            paymentId: paymentId,
            productId: productId || '',
            orderId: orderId || '',
          },
        });

        // In-app notification for seller
        await db.collection(NOTIFICATIONS_COLLECTION).add({
          userId: sellerId,
          type: 'payment',
          title: '💰 Payment Received!',
          message: `You received \$${amount} for your product`,
          relatedId: paymentId,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Notify buyer
      const buyerToken = await getUserToken(buyerId);
      if (buyerToken) {
        await admin.messaging().send({
          token: buyerToken,
          notification: {
            title: '✅ Purchase Complete!',
            body: `Your order of \$${amount} has been confirmed`,
          },
          data: {
            type: 'payment_made',
            paymentId: paymentId,
            productId: productId || '',
            orderId: orderId || '',
          },
        });

        // In-app notification for buyer
        await db.collection(NOTIFICATIONS_COLLECTION).add({
          userId: buyerId,
          type: 'payment',
          title: '✅ Purchase Complete!',
          message: `Your order of \$${amount} has been confirmed`,
          relatedId: paymentId,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log('[PaymentCompleted] Notifications sent');

    } catch (error) {
      console.error('[PaymentCompleted] Error:', error);
    }
  });

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Get all user tokens from Firestore
 */
async function getAllUserTokens() {
  const snapshot = await db.collection(USERS_COLLECTION)
    .where('fcmToken', '!=', null)
    .select('fcmToken')
    .get();
  
  return snapshot.docs
    .map(doc => doc.data().fcmToken)
    .filter(token => token && token.length > 0);
}

/**
 * Get all user tokens except a specific user
 */
async function getAllUserTokensExcept(excludeUserId) {
  const snapshot = await db.collection(USERS_COLLECTION)
    .where('fcmToken', '!=', null)
    .where(admin.firestore.FieldPath.documentId(), '!=', excludeUserId)
    .select('fcmToken')
    .get();
  
  return snapshot.docs
    .map(doc => doc.data().fcmToken)
    .filter(token => token && token.length > 0);
}

/**
 * Get specific user's token
 */
async function getUserToken(userId) {
  if (!userId) return null;
  
  try {
    const doc = await db.collection(USERS_COLLECTION).doc(userId).get();
    if (doc.exists) {
      const data = doc.data();
      return data?.fcmToken || null;
    }
    return null;
  } catch (error) {
    console.error('[getUserToken] Error:', error);
    return null;
  }
}

/**
 * Remove invalid tokens from Firestore
 */
async function removeInvalidTokens(tokens) {
  const usersSnapshot = await db.collection(USERS_COLLECTION)
    .where('fcmToken', 'in', tokens)
    .get();

  const batch = db.batch();
  
  usersSnapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      fcmToken: admin.firestore.FieldValue.delete(),
      tokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  console.log(`[removeInvalidTokens] Removed ${tokens.length} invalid tokens`);
}

/**
 * Send notification to a topic
 */
async function sendTopicNotification(topic, title, body, data) {
  await admin.messaging().send({
    topic: topic,
    notification: {
      title: title,
      body: body,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  });
}

/**
 * Send batch notifications
 */
async function sendBatchNotifications(tokens, notification) {
  if (tokens.length === 0) return;

  // Split into batches of 500
  for (let i = 0; i < tokens.length; i += 500) {
    const batch = tokens.slice(i, i + 500);
    try {
      await admin.messaging().sendEachForMulticast({
        tokens: batch,
        notification: notification,
        data: {
          ...notification.data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
        },
      });
    } catch (error) {
      console.error('[sendBatchNotifications] Error:', error);
    }
  }
}

/**
 * Scheduled function to clean up old notifications (runs daily)
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      
      // Delete old read notifications
      const snapshot = await db.collection(NOTIFICATIONS_COLLECTION)
        .where('read', '==', true)
        .where('createdAt', '<', thirtyDaysAgo)
        .limit(1000)
        .get();

      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`[cleanupOldNotifications] Deleted ${snapshot.docs.length} old notifications`);

    } catch (error) {
      console.error('[cleanupOldNotifications] Error:', error);
    }
  });

console.log('[Functions] Notification functions loaded');

// ============================================================================
// WELCOME CAMPAIGN - Send welcome to new users
// ============================================================================

/**
 * Trigger: HTTP call
 * Action: Send welcome notification to all users or new users
 * 
 * Usage: 
 * - firebase functions:shell
 * - sendWelcomeCampaign() - sends to all users without welcome
 * - sendWelcomeCampaign(true) - sends only to users created in last 24 hours
 */
exports.sendWelcomeCampaign = functions.https.onCall(async (data, context) => {
  requireAdminCaller(context);
  console.log('[WelcomeCampaign] Starting campaign...');
  
  try {
    const newUsersOnly = data?.newUsersOnly || false;
    let usersSnapshot;
    
    if (newUsersOnly) {
      // Get users created in last 24 hours
      const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
      usersSnapshot = await db.collection(USERS_COLLECTION)
        .where('createdAt', '>=', yesterday)
        .get();
    } else {
      // Get all users who haven't received welcome
      usersSnapshot = await db.collection(USERS_COLLECTION)
        .where('welcomeSent', '!=', true)
        .limit(100)
        .get();
    }
    
    let sentCount = 0;
    const now = Date.now();
    
    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const token = userData.fcmToken;
      const userName = userData.name || 'User';
      const userId = userDoc.id;
      
      // Check if we should send (has token)
      if (!token) {
        continue;
      }
      
      // Create in-app notification
      await db.collection(NOTIFICATIONS_COLLECTION).add({
        userId: userId,
        title: '🎉 Welcome to Olmeg Connect!',
        body: `Hi ${userName}! Welcome to your marketplace. Browse products, post listings, and connect with sellers!`,
        type: 'welcome',
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // Try to send push notification
      try {
        await admin.messaging().send({
          token: token,
          notification: {
            title: '🎉 Welcome to Olmeg Connect!',
            body: `Hi ${userName}! Welcome to your marketplace.`,
          },
          data: {
            type: 'welcome',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            priority: 'high',
            notification: {
              channel_id: 'olmeg_connect_channel',
            },
          },
        });
      } catch (e) {
        console.log('[WelcomeCampaign] Push error for', userId, e.message);
      }
      
      // Mark welcome as sent
      await db.collection(USERS_COLLECTION).doc(userId).set({
        welcomeSent: true,
        welcomeSentAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      
      sentCount++;
    }
    
    console.log(`[WelcomeCampaign] Sent to ${sentCount} users`);
    return { success: true, sentCount: sentCount };
    
  } catch (error) {
    console.error('[WelcomeCampaign] Error:', error);
    return { success: false, error: error.message };
  }
});

// ============================================================================
// BLAST CAMPAIGN - Send to all users
// ============================================================================

/**
 * Trigger: HTTP call
 * Action: Send custom notification to all users
 * 
 * Usage with curl:
 * curl -X POST "https://us-central1-YOUR_PROJECT.cloudfunctions.net/blastCampaign" \
 *   -H "Content-Type: application/json" \
 *   -d '{"title":"Your Title","body":"Your Message"}'
 */
exports.blastCampaign = functions.https.onCall(async (data, context) => {
  requireAdminCaller(context);
  console.log('[BlastCampaign] Starting campaign...');
  
  try {
    const { title, body } = data;
    
    if (!title || !body) {
      return { success: false, error: 'Title and body required' };
    }
    
    // Get all users with tokens
    const usersSnapshot = await db.collection(USERS_COLLECTION)
      .where('fcmToken', '!=', null)
      .select('fcmToken')
      .get();
    
    const tokens = usersSnapshot.docs
      .map(doc => doc.data().fcmToken)
      .filter(t => t && t.length > 0);
    
    if (tokens.length === 0) {
      return { success: true, sentCount: 0, message: 'No tokens found' };
    }
    
    // Send in batches
    let sentCount = 0;
    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: batch,
          notification: { title, body },
          data: { type: 'campaign', click_action: 'FLUTTER_NOTIFICATION_CLICK' },
        });
        sentCount += response.successCount;
      } catch (e) {
        console.log('[BlastCampaign] Batch error:', e.message);
      }
    }
    
    console.log(`[BlastCampaign] Sent to ${sentCount} users`);
    return { success: true, sentCount: sentCount };
    
  } catch (error) {
    console.error('[BlastCampaign] Error:', error);
    return { success: false, error: error.message };
  }
});

// ============================================================================
// SCHEDULED CAMPAIGN - Daily promotion (runs via Cloud Scheduler)
// ============================================================================

/**
 * Trigger: Cloud Scheduler (every day at 9am)
 * Action: Send daily promotion/discount notification
 */
exports.dailyPromotionCampaign = functions.pubsub
  .schedule('every day 09:00')
  .onRun(async (context) => {
    console.log('[DailyPromotion] Starting...');
    
    try {
      const title = '🔥 Daily Deals!';
      const body = 'Check out new products added today. Great deals await!';
      
      const usersSnapshot = await db.collection(USERS_COLLECTION)
        .where('fcmToken', '!=', null)
        .limit(500)
        .get();
      
      const tokens = usersSnapshot.docs
        .map(doc => doc.data().fcmToken)
        .filter(t => t && t.length > 0);
      
      for (let i = 0; i < tokens.length; i += 500) {
        await admin.messaging().sendEachForMulticast({
          tokens: tokens.slice(i, i + 500),
          notification: { title, body },
          data: { type: 'promotion', click_action: 'FLUTTER_NOTIFICATION_CLICK' },
        });
      }
      
      console.log('[DailyPromotion] Done');
    } catch (error) {
      console.error('[DailyPromotion] Error:', error);
    }
  });
