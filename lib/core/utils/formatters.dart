import 'package:intl/intl.dart';

/// Format a number as Vietnamese Đồng: "123.456 đ"
String formatVND(double amount) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return '${formatter.format(amount.round())} đ';
}

/// Format a DateTime as "dd/MM/yyyy"
String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

/// Format a DateTime as "dd/MM"
String formatShortDate(DateTime date) {
  return DateFormat('dd/MM').format(date);
}
