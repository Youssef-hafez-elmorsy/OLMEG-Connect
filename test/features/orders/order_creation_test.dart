import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_connect/features/cart/domain/entities/cart_item.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';
import 'package:olmeg_connect/features/profile/domain/entities/address_entity.dart';

void main() {
  group('Order creation', () {
    test('builds order snapshots from checkout data', () {
      final order = buildOrderFromCheckout(
        id: 'order-1',
        buyerId: 'buyer-1',
        now: DateTime(2026, 5, 11),
        items: const [
          CartItem(
            id: 'product-1',
            title: 'Handmade bag',
            price: 120,
            imageUrl: 'image.png',
            sellerId: 'seller-1',
            sellerName: 'Seller',
            selectedVariant: 'Blue',
            stockQuantity: 5,
            quantity: 2,
          ),
        ],
        address: const AddressEntity(
          id: 'address-1',
          fullName: 'Buyer',
          phone: '01000000000',
          line1: 'Street 1',
          city: 'Cairo',
        ),
        subtotal: 240,
        shippingFee: 0,
        tax: 0,
        discount: 0,
        total: 240,
      );

      expect(order.id, 'order-1');
      expect(order.status, OrderStatus.pendingPayment);
      expect(order.payment.provider, 'paymob');
      expect(order.payment.status, PaymentSummaryStatus.pending);
      expect(order.sellerIds, ['seller-1']);
      expect(order.items.single.productId, 'product-1');
      expect(order.items.single.lineTotal, 240);
      expect(order.shippingAddress.city, 'Cairo');
    });

    test('checkout fingerprint is stable regardless of item order', () {
      const first = CartItem(
        id: 'a',
        title: 'A',
        price: 10,
        imageUrl: '',
        sellerId: 'seller',
        sellerName: 'Seller',
        quantity: 1,
      );
      const second = CartItem(
        id: 'b',
        title: 'B',
        price: 20,
        imageUrl: '',
        sellerId: 'seller',
        sellerName: 'Seller',
        quantity: 2,
      );

      expect(
        checkoutFingerprint(
            buyerId: 'buyer', items: [first, second], total: 50),
        checkoutFingerprint(
            buyerId: 'buyer', items: [second, first], total: 50),
      );
    });
  });

  group('Order payment status mapping', () {
    test('paid payment marks order paid', () {
      expect(
        orderStatusForPayment(PaymentSummaryStatus.paid),
        OrderStatus.paid,
      );
    });

    test('failed payment keeps order pending payment', () {
      expect(
        orderStatusForPayment(PaymentSummaryStatus.failed),
        OrderStatus.pendingPayment,
      );
    });
  });

  group('Order status transitions', () {
    test('allows normal fulfillment path', () {
      expect(
        isAllowedOrderStatusTransition(
          OrderStatus.pendingPayment,
          OrderStatus.paid,
        ),
        isTrue,
      );
      expect(
        isAllowedOrderStatusTransition(OrderStatus.paid, OrderStatus.preparing),
        isTrue,
      );
      expect(
        isAllowedOrderStatusTransition(
          OrderStatus.preparing,
          OrderStatus.shipped,
        ),
        isTrue,
      );
      expect(
        isAllowedOrderStatusTransition(
          OrderStatus.shipped,
          OrderStatus.delivered,
        ),
        isTrue,
      );
    });

    test('blocks impossible fulfillment jumps', () {
      expect(
        isAllowedOrderStatusTransition(
          OrderStatus.pendingPayment,
          OrderStatus.shipped,
        ),
        isFalse,
      );
      expect(
        isAllowedOrderStatusTransition(
          OrderStatus.cancelled,
          OrderStatus.paid,
        ),
        isFalse,
      );
      expect(
        isAllowedOrderStatusTransition(
          OrderStatus.refunded,
          OrderStatus.delivered,
        ),
        isFalse,
      );
    });
  });
}
