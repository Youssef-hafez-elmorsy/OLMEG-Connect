import 'package:equatable/equatable.dart';

class SellerProfileEntity extends Equatable {
  final String userId;
  final String displayName;
  final String storeName;
  final double ratingAverage;
  final int ratingCount;
  final String verificationStatus;
  final String returnPolicy;
  final List<String> shippingMethods;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SellerProfileEntity({
    required this.userId,
    required this.displayName,
    required this.storeName,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.verificationStatus = 'unverified',
    this.returnPolicy = '',
    this.shippingMethods = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  SellerProfileEntity copyWith({
    String? displayName,
    String? storeName,
    double? ratingAverage,
    int? ratingCount,
    String? verificationStatus,
    String? returnPolicy,
    List<String>? shippingMethods,
    DateTime? updatedAt,
  }) {
    return SellerProfileEntity(
      userId: userId,
      displayName: displayName ?? this.displayName,
      storeName: storeName ?? this.storeName,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      shippingMethods: shippingMethods ?? this.shippingMethods,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        storeName,
        ratingAverage,
        ratingCount,
        verificationStatus,
        returnPolicy,
        shippingMethods,
        createdAt,
        updatedAt,
      ];
}
