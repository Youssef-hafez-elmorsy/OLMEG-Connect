import 'package:cloud_firestore/cloud_firestore.dart';
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
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
      category: d['category'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      sellerId: d['sellerId'] ?? '',
      sellerName: d['sellerName'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
