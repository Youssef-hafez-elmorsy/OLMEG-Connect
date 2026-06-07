import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';
import 'package:olmeg_connect/features/cart/presentation/screens/checkout_review_screen.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/products/presentation/widgets/product_card.dart';

void main() {
  testWidgets('modern product card surfaces buyer trust signals',
      (tester) async {
    final product = ProductEntity(
      id: 'product-1',
      title: 'Handmade ceramic lamp with warm finish',
      description: 'A polished handmade product.',
      price: 850,
      originalPrice: 1000,
      category: 'Handmade',
      imageUrl: '',
      sellerId: 'seller-1',
      sellerName: 'Olmeg Studio',
      stock: 4,
      rating: 4.7,
      viewCount: 128,
      sellerMerchantVerificationStatus: MerchantVerificationStatus.approved,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 330,
            child: ProductCard(product: product),
          ),
        ),
      ),
    );

    expect(find.text('Delivery ready'), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
    expect(find.text('Verified seller'), findsOneWidget);
    expect(find.text('4 in stock'), findsOneWidget);
    expect(find.text('Olmeg Studio'), findsOneWidget);
  });

  testWidgets('unrated product card shows category instead of New',
      (tester) async {
    final product = ProductEntity(
      id: 'product-2',
      title: 'Handmade wall art',
      description: 'A category-first card.',
      price: 450,
      category: 'Handmade',
      imageUrl: '',
      sellerId: 'seller-1',
      sellerName: 'Olmeg Studio',
      stock: 2,
      rating: 0,
      sellerMerchantVerificationStatus: MerchantVerificationStatus.approved,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 330,
            child: ProductCard(product: product),
          ),
        ),
      ),
    );

    expect(find.text('Handmade'), findsOneWidget);
    expect(find.text('New'), findsNothing);
  });

  testWidgets('checkout refresh explains blocked state with modern copy',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CheckoutReviewScreen(),
        ),
      ),
    );

    expect(find.text('Complete the missing checkout step'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Create order and continue to payment'),
      300,
    );
    expect(
      find.text('Add at least one available item to continue.'),
      findsOneWidget,
    );
  });
}
