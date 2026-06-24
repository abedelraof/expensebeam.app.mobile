import 'package:intl/intl.dart';

String formatCurrency(double amount, String currency) {
  final fmt = NumberFormat('#,##0.00');
  return '${fmt.format(amount)} $currency';
}

String formatAmount(double amount) => NumberFormat('#,##0.00').format(amount);

String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

String formatShortDate(DateTime date) => DateFormat('MMM d').format(date);
