// Package imports:
import 'package:intl/intl.dart';

String formatNumber(double value) {
  final formatter = NumberFormat('###,###,###', 'en_US');
  return formatter.format(value);
}

String formatNumber2(double value) {
  final formatter = NumberFormat('###,###,##0.00', 'en_US');
  return formatter.format(value);
}

String formatNumber4(double value) {
  final formatter = NumberFormat('###,###,##0.0000', 'en_US');
  return formatter.format(value);
}
