import 'dart:collection';

import 'package:olmeg_connect/features/posts/models/post_model.dart';

/// Lightweight read-only product DTO used only for matching.
/// Do NOT modify the actual product schema/entity.
class ProductInfo {
  final String id;
  final String title;
  final String description;
  final String category;

  ProductInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
  });
}

/// Internal helper to hold a product with its computed score.
class _ScoredProduct {
  final ProductInfo product;
  final int score;
  _ScoredProduct(this.product, this.score);
}

/// Keyword-based matcher (Level 1 AI-like approach, offline)
class PostProductMatcher {
  // English stop words (basic)
  static const Set<String> _englishStops = {
    'the','and','a','an','in','on','at','for','to','of','with','is','it','this','that','these','those','i','you','we','our','your','but','be','as'
  };

  // Arabic stop words (basic)
  static const Set<String> _arabicStops = {
    'و','في','من','على','مع','عن','إلى','ف','لم','لن','إن','أن','هذا','هذه','ذلك','تلك','هناك','هو','هي','كان','لكن','ما','حتى','لها','له'
  };

  // Simple bilingual synonym dictionary (lowercase keys)
  static const Map<String,List<String>> _synonyms = {
    // English
    'phone': ['phone','mobile','cellphone','smartphone'],
    'mobile': ['mobile','phone','cellphone','smartphone'],
    'laptop': ['laptop','notebook'],
    'notebook': ['notebook','laptop'],
    'tv': ['tv','television'],
    'television': ['television','tv'],
    // Arabic synonyms (base forms)
    'هاتف': ['هاتف','جوال','موبايل','هاتف محمول'],
    'جوال': ['جوال','هاتف','موبايل','هاتف محمول'],
    'موبايل': ['موبايل','هاتف','جوال','هاتف محمول'],
    'هاتف محمول': ['هاتف','هاتف محمول','موبايل','جوال'],
  };

  // Simple in-memory cache per postId
  static final Map<String,List<ProductInfo>> _cache = {};

  // 1) Keyword extraction from text
  static List<String> extractKeywords(String text) {
    if (text.isEmpty) return [];
    String t = text.toLowerCase();

    // Remove punctuation (keep Latin+Arabic characters)
    final RegExp punct = RegExp(r"[^a-z0-9\u0600-\u06FF\s]");
    t = t.replaceAll(punct, ' ');

    // Split and filter
    final parts = t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final List<String> keywords = [];
    for (final w in parts) {
      if (w.length < 2) continue;
      if (_englishStops.contains(w)) continue;
      if (_arabicStops.contains(w)) continue;
      keywords.add(w);
    }

    // Deduplicate while preserving order
    return LinkedHashSet<String>.from(keywords).toList();
  }

  // 2) Resolve synonyms for a given keyword
  static List<String> _resolveSynonyms(String word) {
    final lower = word.toLowerCase();
    final list = _synonyms[lower];
    if (list != null && list.isNotEmpty) {
      return list.map((s) => s.toLowerCase()).toList();
    }
    return [lower];
  }

  // 3) Score a single product against a post
  static int _scorePostAgainstProduct(PostModel post, ProductInfo product, List<String> keywords) {
    final String title = product.title.toLowerCase();
    final String description = product.description.toLowerCase();
    final String category = product.category.toLowerCase();

    int score = 0;
    for (final kw in keywords) {
      final syns = _resolveSynonyms(kw);
      for (final syn in syns) {
        if (title.contains(syn)) {
          score += 3;
          break;
        }
        if (description.contains(syn)) {
          score += 2;
          // do not break; allow additional synonyms to contribute
        }
        if (category == syn) {
          score += 1;
          break;
        }
      }
    }
    return score;
  }

  // 4) Public API: get top suggestions for a post from a list of products
  static List<ProductInfo> getSuggestedProducts(
    PostModel post,
    List<ProductInfo> products,
  ) {
    final key = post.id;
    if (_cache.containsKey(key)) return List<ProductInfo>.from(_cache[key]!);

    // Optional initial category pre-filter (matches the spec)
    final postCat = (post.category ?? '').toLowerCase().trim();
    List<ProductInfo> candidates = products;
    if (postCat.isNotEmpty) {
      final filtered = products.where((p) => p.category.toLowerCase() == postCat).toList();
      if (filtered.isNotEmpty) candidates = filtered;
    }

    final postText = '${post.title ?? ''} ${post.description ?? ''}';
    final keywords = extractKeywords(postText);

    final List<_ScoredProduct> scored = [];
    for (final p in candidates) {
      final s = _scorePostAgainstProduct(post, p, keywords);
      if (s > 0) scored.add(_ScoredProduct(p, s));
    }

    scored.sort((a,b) => b.score.compareTo(a.score));
    final top = scored.take(10).map((e) => e.product).toList();

    _cache[key] = top;
    return top;
  }

  // Exposed for unit tests / debugging
  static int calculateScore(PostModel post, ProductInfo product) {
    final keywords = extractKeywords('${post.title ?? ''} ${post.description ?? ''}');
    return _scorePostAgainstProduct(post, product, keywords);
  }

  /// Clear cache (e.g., on logout or data refresh)
  static void clearCache() => _cache.clear();
}