import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, price, category, sellerId];
}
