import 'package:equatable/equatable.dart';

class CartEntity extends Equatable {
  final String id;
  final String oderId;
  final String productId;
  final String productTitle;
  final double price;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final int quantity;
  final DateTime addedAt;

  const CartEntity({
    required this.id,
    required this.oderId,
    required this.productId,
    required this.productTitle,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    required this.addedAt,
  });

  double get total => price * quantity;

  @override
  List<Object?> get props => [id, oderId, productId, price, quantity];
}