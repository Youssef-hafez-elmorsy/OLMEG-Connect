import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _egp = NumberFormat.currency(
    locale: 'en_EG',
    symbol: 'EGP ',
    decimalDigits: 0,
  );

  static String egp(num amount) => _egp.format(amount);
}
