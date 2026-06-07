import 'package:equatable/equatable.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';
import 'package:olmeg_connect/features/products/domain/services/delivery_eligibility.dart';

class ProductVariant extends Equatable {
  final String id;
  final String label;
  final Map<String, String> attributes;
  final double? priceDelta;
  final int stockQuantity;

  const ProductVariant({
    required this.id,
    required this.label,
    this.attributes = const {},
    this.priceDelta,
    this.stockQuantity = 0,
  });

  @override
  List<Object?> get props => [id, label, attributes, priceDelta, stockQuantity];
}

class ProductEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String? subcategory;
  final String? categoryId;
  final String? subCategoryId;
  final String? subCategoryName;
  final String? condition;
  final String imageUrl;
  final List<String> images;
  final String city;
  final String? phone;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final double sellerRating;
  final int sellerProducts;
  final double rating;
  final int reviewsCount;
  final List<String> features;
  final List<String> colors;
  final List<ProductVariant> variants;
  final int stock;
  final String status;
  final String? brand;
  final String? returnPolicy;
  final String? deliveryEstimate;
  final MerchantVerificationStatus sellerMerchantVerificationStatus;
  final bool isFavorite;
  final int viewCount;
  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    this.subcategory,
    this.categoryId,
    this.subCategoryId,
    this.subCategoryName,
    this.condition,
    required this.imageUrl,
    this.images = const [],
    this.city = '',
    this.phone,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar,
    this.sellerRating = 0,
    this.sellerProducts = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    this.features = const [],
    this.colors = const [],
    this.variants = const [],
    this.stock = 1,
    this.status = 'active',
    this.brand,
    this.returnPolicy,
    this.deliveryEstimate,
    this.sellerMerchantVerificationStatus = MerchantVerificationStatus.none,
    this.isFavorite = false,
    this.viewCount = 0,
    required this.createdAt,
  });

  double? get salePrice => hasDiscount ? price : null;
  int get stockQuantity => stock;
  double get ratingAverage => rating;
  int get ratingCount => reviewsCount;
  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  int get discountPercent =>
      hasDiscount ? ((1 - price / originalPrice!) * 100).round() : 0;
  bool get inStock => stock > 0;
  bool get isNew => category.toLowerCase() == 'new';
  bool get isUsed => category.toLowerCase() == 'used';
  bool get isHandicraft {
    final normalized = category.toLowerCase().trim();
    return normalized == 'handicraft' ||
        normalized == 'handcraft' ||
        normalized == 'handmade';
  }

  bool get supportsDelivery => isDeliveryEligible(
        isHandicraft: isHandicraft,
        merchantStatus: sellerMerchantVerificationStatus,
      );
  String get deliveryDisplayText => supportsDelivery
      ? deliveryEstimate ?? 'Delivery available for handmade products'
      : isHandicraft
          ? 'Delivery is available after merchant verification is approved'
          : 'Contact the seller to arrange pickup or delivery';

  List<String> get allImages {
    final unique = <String>[];
    for (final image in [imageUrl, ...images]) {
      if (image.isNotEmpty && !unique.contains(image)) {
        unique.add(image);
      }
    }
    return unique;
  }

  ProductEntity copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? subcategory,
    String? categoryId,
    String? subCategoryId,
    String? subCategoryName,
    String? condition,
    String? imageUrl,
    List<String>? images,
    String? city,
    String? phone,
    String? sellerId,
    String? sellerName,
    String? sellerAvatar,
    double? sellerRating,
    int? sellerProducts,
    double? rating,
    int? reviewsCount,
    List<String>? features,
    List<String>? colors,
    List<ProductVariant>? variants,
    int? stock,
    String? status,
    String? brand,
    String? returnPolicy,
    String? deliveryEstimate,
    MerchantVerificationStatus? sellerMerchantVerificationStatus,
    bool? isFavorite,
    int? viewCount,
    DateTime? createdAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerProducts: sellerProducts ?? this.sellerProducts,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      features: features ?? this.features,
      colors: colors ?? this.colors,
      variants: variants ?? this.variants,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      brand: brand ?? this.brand,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      deliveryEstimate: deliveryEstimate ?? this.deliveryEstimate,
      sellerMerchantVerificationStatus: sellerMerchantVerificationStatus ??
          this.sellerMerchantVerificationStatus,
      isFavorite: isFavorite ?? this.isFavorite,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        price,
        category,
        sellerId,
        status,
        isFavorite,
        viewCount,
      ];
}
