import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_connect/features/cart/domain/entities/cart_item.dart';

void main() {
  group('CartTotals', () {
    test('calculates subtotal from active line items', () {
      final totals = CartTotals.fromItems(const [
        CartItem(
          id: 'p1',
          title: 'Phone',
          price: 100,
          imageUrl: '',
          sellerId: 's1',
          sellerName: 'Seller',
          stockQuantity: 5,
          quantity: 2,
        ),
        CartItem(
          id: 'p2',
          title: 'Case',
          price: 50,
          imageUrl: '',
          sellerId: 's1',
          sellerName: 'Seller',
          stockQuantity: 3,
          quantity: 1,
        ),
      ]);

      expect(totals.subtotal, 250);
      expect(totals.total, 250);
    });

    test('excludes saved for later items from totals', () {
      final totals = CartTotals.fromItems(const [
        CartItem(
          id: 'p1',
          title: 'Phone',
          price: 100,
          imageUrl: '',
          sellerId: 's1',
          sellerName: 'Seller',
          stockQuantity: 5,
          quantity: 2,
        ),
        CartItem(
          id: 'p2',
          title: 'Saved',
          price: 999,
          imageUrl: '',
          sellerId: 's1',
          sellerName: 'Seller',
          stockQuantity: 1,
          savedForLater: true,
          quantity: 1,
        ),
      ]);

      expect(totals.subtotal, 200);
    });

    test('applies shipping discount and tax to total', () {
      final totals = CartTotals.fromItems(
        const [
          CartItem(
            id: 'p1',
            title: 'Phone',
            price: 100,
            imageUrl: '',
            sellerId: 's1',
            sellerName: 'Seller',
            stockQuantity: 5,
            quantity: 1,
          ),
        ],
        shipping: 20,
        discount: 15,
        tax: 5,
      );

      expect(totals.total, 110);
    });

    test('reports invalid quantity when quantity exceeds stock', () {
      const item = CartItem(
        id: 'p1',
        title: 'Phone',
        price: 100,
        imageUrl: '',
        sellerId: 's1',
        sellerName: 'Seller',
        stockQuantity: 1,
        quantity: 2,
      );

      expect(item.hasValidQuantity, isFalse);
    });
  });
}
