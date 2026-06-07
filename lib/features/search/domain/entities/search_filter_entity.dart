import 'package:equatable/equatable.dart';

class SearchFilterEntity extends Equatable {
  final String? query;
  final double? minPrice;
  final double? maxPrice;
  final String? category;
  final String? condition;
  final String? location;
  final double? minRating;
  final bool? onlyAvailable;
  final String? sellerId;
  final String sortBy;

  const SearchFilterEntity({
    this.query,
    this.minPrice,
    this.maxPrice,
    this.category,
    this.condition,
    this.location,
    this.minRating,
    this.onlyAvailable,
    this.sellerId,
    this.sortBy = 'newest',
  });

  @override
  List<Object?> get props => [
        query,
        minPrice,
        maxPrice,
        category,
        condition,
        location,
        minRating,
        onlyAvailable,
        sellerId,
        sortBy,
      ];

  SearchFilterEntity copyWith({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? category,
    String? condition,
    String? location,
    double? minRating,
    bool? onlyAvailable,
    String? sellerId,
    String? sortBy,
  }) {
    return SearchFilterEntity(
      query: query ?? this.query,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      minRating: minRating ?? this.minRating,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      sellerId: sellerId ?? this.sellerId,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
