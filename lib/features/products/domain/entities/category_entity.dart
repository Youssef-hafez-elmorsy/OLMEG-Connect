import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;

  const CategoryEntity({
    required this.id,
    required this.name,
  });

  factory CategoryEntity.fromFirestore(String id, Map<String, dynamic> data) {
    return CategoryEntity(
      id: id,
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

class SubcategoryEntity extends Equatable {
  final String id;
  final String name;
  final String categoryId;

  const SubcategoryEntity({
    required this.id,
    required this.name,
    required this.categoryId,
  });

  factory SubcategoryEntity.fromFirestore(
      String id, Map<String, dynamic> data) {
    return SubcategoryEntity(
      id: id,
      name: data['name'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'categoryId': categoryId,
    };
  }

  @override
  List<Object?> get props => [id, name, categoryId];
}
