import 'package:olmeg_connect/features/cart/domain/entities/cart_item.dart';
import 'package:olmeg_connect/features/profile/domain/entities/address_entity.dart';

class ShippingQuote {
  final String zone;
  final double fee;
  final DateTime estimatedDeliveryDate;
  final int shipmentCount;
  final bool deliveryAvailable;

  const ShippingQuote({
    required this.zone,
    required this.fee,
    required this.estimatedDeliveryDate,
    required this.shipmentCount,
    required this.deliveryAvailable,
  });
}

class ShippingService {
  ShippingService._();

  static const Map<String, double> _cityBaseFees = {
    'cairo': 45,
    'giza': 50,
    'alexandria': 60,
    'mansoura': 70,
    'tanta': 70,
    'zagazig': 75,
  };

  static String normalizeCity(String value) {
    final city = value.trim().toLowerCase();
    if (city.contains('القاهرة')) return 'cairo';
    if (city.contains('الجيزة')) return 'giza';
    if (city.contains('اسكندرية') || city.contains('الإسكندرية')) {
      return 'alexandria';
    }
    return city;
  }

  static ShippingQuote quote({
    required AddressEntity address,
    required List<CartItem> items,
  }) {
    final normalizedCity = normalizeCity(address.city);
    final baseFee = _cityBaseFees[normalizedCity];
    final activeItems = items.where((item) => !item.savedForLater).toList();
    final sellerCount = activeItems.map((item) => item.sellerId).toSet().length;
    final shipmentCount = sellerCount < 1 ? 1 : sellerCount;
    final deliveryAvailable = baseFee != null && activeItems.isNotEmpty;
    final fee = deliveryAvailable ? baseFee + ((shipmentCount - 1) * 20) : 0.0;
    final deliveryDays = normalizedCity == 'cairo' || normalizedCity == 'giza'
        ? 2
        : deliveryAvailable
            ? 4
            : 0;
    return ShippingQuote(
      zone: normalizedCity.isEmpty ? 'unknown' : normalizedCity,
      fee: fee,
      estimatedDeliveryDate: DateTime.now().add(Duration(days: deliveryDays)),
      shipmentCount: shipmentCount,
      deliveryAvailable: deliveryAvailable,
    );
  }
}
