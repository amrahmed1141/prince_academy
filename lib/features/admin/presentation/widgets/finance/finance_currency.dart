import 'package:intl/intl.dart';

abstract final class FinanceCurrency {
  static final NumberFormat full = NumberFormat.currency(
    locale: 'en',
    symbol: '',
    decimalDigits: 2,
  );

  static final NumberFormat compact = NumberFormat.currency(
    locale: 'en',
    symbol: '',
    decimalDigits: 0,
  );

  static String egp(double amount, {bool decimals = true}) {
    final formatted = (decimals ? full : compact).format(amount).trim();
    return '$formatted EGP';
  }

  static String egpPrefix(double amount, {bool decimals = true}) {
    final formatted = (decimals ? full : compact).format(amount).trim();
    return 'EGP $formatted';
  }

  static String short(double amount) {
    if (amount >= 1000) {
      final k = amount / 1000;
      final text = k == k.roundToDouble()
          ? k.toStringAsFixed(0)
          : k.toStringAsFixed(1);
      return 'EGP ${text}k';
    }
    return egpPrefix(amount, decimals: false);
  }
}
