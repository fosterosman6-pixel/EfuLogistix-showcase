import 'i18n.dart';

/// 64500 -> "K64,500" (Malawi Kwacha)
String money(num? value) {
  final n = (value ?? 0).round();
  final digits = n.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '${n < 0 ? '-' : ''}K$digits';
}

/// "5,000" or "K5000" -> 5000
double parseAmount(String text) => double.tryParse(text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

String _two(int n) => n.toString().padLeft(2, '0');

/// "09:42"
String clock(DateTime? d) => d == null ? '--:--' : '${_two(d.hour)}:${_two(d.minute)}';

/// "1 h 12 m" or "35 min"
String durationText(double minutes) {
  int m = minutes.isFinite ? minutes.round() : 0;
  if (m < 1) m = 1; // never "0 min"
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${_two(m % 60)} m';
}

String kmText(double? value) {
  final n = value ?? 0;
  return n < 10 ? '${n.toStringAsFixed(1)} km' : '${n.round()} km';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Short month name in the chosen language (Jan -> Jan, Mar -> Mal ...).
String monthShort(int month) => tx(_months[month - 1]);

/// Short weekday name in the chosen language (Mon -> Lol ...).
String weekdayShort(int weekday) => tx(const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1]);

String shortDate(DateTime d) => '${d.day} ${monthShort(d.month)}';

enum Period { today, week, month }

/// Start of today / this week (Monday) / this month, local time.
DateTime periodStart(Period p) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  switch (p) {
    case Period.today:
      return today;
    case Period.week:
      return today.subtract(Duration(days: today.weekday - 1));
    case Period.month:
      return DateTime(now.year, now.month, 1);
  }
}

/// For database filters.
String isoUtc(DateTime d) => d.toUtc().toIso8601String();

/// 10.0 -> "10", 12.5 -> "12.5"
String trimPct(num v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
