import 'package:flutter_test/flutter_test.dart';
import 'package:efulogistix_fleet/format.dart';
import 'package:efulogistix_fleet/models.dart';

void main() {
  group('money', () {
    test('groups thousands with commas and a K', () {
      expect(money(64500), 'K64,500');
      expect(money(1200), 'K1,200');
      expect(money(0), 'K0');
      expect(money(1234567), 'K1,234,567');
    });
    test('rounds, handles null and negatives', () {
      expect(money(999.6), 'K1,000');
      expect(money(null), 'K0');
      expect(money(-2500), '-K2,500');
    });
  });

  group('parseAmount', () {
    test('reads amounts people type', () {
      expect(parseAmount('5,000'), 5000);
      expect(parseAmount('K5000'), 5000);
      expect(parseAmount('12.5'), 12.5);
    });
    test('returns 0 for nothing usable', () {
      expect(parseAmount(''), 0);
      expect(parseAmount('abc'), 0);
    });
  });

  group('time and distance text', () {
    test('clock pads minutes and hours', () {
      expect(clock(DateTime(2026, 11, 18, 9, 5)), '09:05');
      expect(clock(null), '--:--');
    });
    test('durationText never says 0 min', () {
      expect(durationText(0), '1 min');
      expect(durationText(35), '35 min');
      expect(durationText(72), '1 h 12 m');
      expect(durationText(double.nan), '1 min');
    });
    test('kmText shows a decimal only for short distances', () {
      expect(kmText(0), '0.0 km');
      expect(kmText(4.26), '4.3 km');
      expect(kmText(190.4), '190 km');
      expect(kmText(null), '0.0 km');
    });
    test('trimPct drops a trailing .0', () {
      expect(trimPct(10.0), '10');
      expect(trimPct(12.5), '12.5');
    });
  });

  group('periodStart', () {
    test('today starts at midnight', () {
      final d = periodStart(Period.today);
      expect([d.hour, d.minute, d.second], [0, 0, 0]);
    });
    test('week starts on a Monday and is not in the future', () {
      final d = periodStart(Period.week);
      expect(d.weekday, DateTime.monday);
      expect(d.isAfter(DateTime.now()), isFalse);
    });
    test('month starts on the 1st', () {
      expect(periodStart(Period.month).day, 1);
    });
  });

  group('models helpers', () {
    test('toDouble and toInt accept numbers, text and null', () {
      expect(toDouble(3), 3.0);
      expect(toDouble('4.5'), 4.5);
      expect(toDouble(null), 0);
      expect(toDouble('x'), 0);
      expect(toInt('7'), 7);
      expect(toInt(2.6), 3);
    });
    test('toIntOrNull keeps null', () {
      expect(toIntOrNull(null), isNull);
      expect(toIntOrNull('5'), 5);
    });
    test('tonnesText uses singular for 1 tonne', () {
      expect(tonnesText(1), '1 tonne');
      expect(tonnesText(3), '3 tonnes');
      expect(tonnesText(2.5), '2.5 tonnes');
    });
  });
}
