import 'package:equatable/equatable.dart';

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
  final int stock;
  final bool isFavorite;
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
    this.stock = 1,
    this.isFavorite = false,
    required this.createdAt,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  int get discountPercent =>
      hasDiscount ? ((1 - price / originalPrice!) * 100).round() : 0;
  bool get inStock => stock > 0;
  bool get isNew => category.toLowerCase() == 'new';
  bool get isUsed => category.toLowerCase() == 'used';
  bool get isHandicraft => category.toLowerCase() == 'handicraft';

  List<String> get allImages =>
      imageUrl.isNotEmpty ? [imageUrl, ...images] : images;

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
    int? stock,
    bool? isFavorite,
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
      stock: stock ?? this.stock,
      isFavorite: isFavorite ?? this.isFavorite,
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
        isFavorite,
      ];
}