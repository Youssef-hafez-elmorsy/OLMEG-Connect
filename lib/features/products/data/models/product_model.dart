import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.category,
    required super.imageUrl,
    required super.sellerId,
    required super.sellerName,
    required super.createdAt,
    super.categoryId,
    super.subCategoryId,
    super.subCategoryName,
    super.images = const [],
    super.city = '',
    super.condition,
    super.originalPrice,
    super.phone,
    super.sellerAvatar,
    super.sellerRating = 0,
    super.sellerProducts = 0,
    super.rating = 0,
    super.reviewsCount = 0,
    super.features = const [],
    super.colors = const [],
    super.variants = const [],
    super.stock = 1,
    super.status = 'active',
    super.brand,
    super.returnPolicy,
    super.deliveryEstimate,
    super.sellerMerchantVerificationStatus,
    super.viewCount,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final basePrice = (d['price'] as num?)?.toDouble() ?? 0.0;
    final salePriceOverride = (d['salePriceOverride'] as num?)?.toDouble();
    final originalPrice = (d['originalPrice'] as num?)?.toDouble();
    return ProductModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      price: salePriceOverride ?? basePrice,
      category: d['categoryName'] ?? d['category'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      images: List<String>.from(d['images'] ?? const []),
      sellerId: d['sellerId'] ?? '',
      sellerName: d['sellerName'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      originalPrice: salePriceOverride != null && salePriceOverride < basePrice
          ? basePrice
          : originalPrice,
      categoryId: d['categoryId'] as String?,
      subCategoryId: d['subCategoryId'] as String?,
      subCategoryName: d['subCategoryName'] as String?,
      city: d['city'] as String? ?? d['location'] as String? ?? '',
      phone: d['phone'] as String?,
      condition: d['condition'] as String?,
      sellerAvatar:
          d['sellerAvatar'] as String? ?? d['sellerPhotoUrl'] as String?,
      sellerRating: (d['sellerRating'] as num?)?.toDouble() ?? 0,
      sellerProducts: (d['sellerProducts'] as num?)?.toInt() ?? 0,
      rating: (d['ratingAverage'] as num?)?.toDouble() ??
          (d['rating'] as num?)?.toDouble() ??
          0,
      reviewsCount: (d['ratingCount'] as num?)?.toInt() ??
          (d['reviewsCount'] as num?)?.toInt() ??
          0,
      features: List<String>.from(d['features'] ?? const []),
      colors: List<String>.from(d['colors'] ?? const []),
      variants: _parseVariants(d['variants']),
      stock: (d['stockQuantity'] as num?)?.toInt() ??
          (d['stock'] as num?)?.toInt() ??
          1,
      status: d['status'] as String? ??
          ((d['moderationStatus'] as String?) == 'approved'
              ? 'active'
              : d['moderationStatus'] as String? ?? 'active'),
      brand: d['brand'] as String?,
      returnPolicy: d['returnPolicy'] as String?,
      deliveryEstimate: d['deliveryEstimate'] as String?,
      viewCount: (d['viewCount'] as num?)?.toInt() ?? 0,
      sellerMerchantVerificationStatus: merchantVerificationStatusFromString(
        d['sellerMerchantVerificationStatus'] as String?,
      ),
    );
  }

  static List<ProductVariant> _parseVariants(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((raw) {
      final data = Map<String, dynamic>.from(raw);
      final attributes = <String, String>{};
      final rawAttributes = data['attributes'];
      if (rawAttributes is Map) {
        rawAttributes.forEach((key, value) {
          attributes[key.toString()] = value.toString();
        });
      }
      return ProductVariant(
        id: data['id']?.toString() ?? '',
        label: data['label']?.toString() ?? '',
        attributes: attributes,
        priceDelta: (data['priceDelta'] as num?)?.toDouble(),
        stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'stock': stock,
      'stockQuantity': stockQuantity,
      'status': status,
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (originalPrice != null) map['originalPrice'] = originalPrice;
    if (category.isNotEmpty) map['categoryName'] = category;
    if (images.isNotEmpty) map['images'] = images;
    if (city.isNotEmpty) map['city'] = city;
    if (phone != null) map['phone'] = phone;
    if (condition != null) map['condition'] = condition;
    if (brand != null) map['brand'] = brand;
    if (returnPolicy != null) map['returnPolicy'] = returnPolicy;
    if (deliveryEstimate != null) map['deliveryEstimate'] = deliveryEstimate;
    if (features.isNotEmpty) map['features'] = features;
    if (colors.isNotEmpty) map['colors'] = colors;
    if (sellerAvatar != null) map['sellerAvatar'] = sellerAvatar;
    if (sellerRating > 0) map['sellerRating'] = sellerRating;
    if (sellerProducts > 0) map['sellerProducts'] = sellerProducts;
    map['sellerMerchantVerificationStatus'] =
        merchantVerificationStatusToString(sellerMerchantVerificationStatus);
    if (variants.isNotEmpty) {
      map['variants'] = variants
          .map((variant) => {
                'id': variant.id,
                'label': variant.label,
                'attributes': variant.attributes,
                'priceDelta': variant.priceDelta,
                'stockQuantity': variant.stockQuantity,
              })
          .toList();
    }
    if (categoryId != null) map['categoryId'] = categoryId;
    if (subCategoryId != null) map['subCategoryId'] = subCategoryId;
    if (subCategoryName != null) map['subCategoryName'] = subCategoryName;
    return map;
  }
}
