import 'package:flutter_test/flutter_test.dart';
import 'package:efulogistix_fleet/i18n.dart';
import 'package:efulogistix_fleet/notice_text.dart';
import 'package:efulogistix_fleet/vehicle_art.dart';

void main() {
  tearDown(() => language.value = 'en');

  group('translation helpers', () {
    test('English text stays as written', () {
      language.value = 'en';
      expect(tx('Anything at all'), 'Anything at all');
      expect(txf('Boarding ticket · #%s', ['66']), 'Boarding ticket · #66');
    });
    test('text with no translation stays English in Chichewa', () {
      language.value = 'ny';
      expect(tx('A sentence nobody translated yet'), 'A sentence nobody translated yet');
    });
    test('%% becomes a single percent sign', () {
      expect(txf('Fee is 10%%'), 'Fee is 10%');
    });
    test('noticeText translates known patterns only in Chichewa', () {
      language.value = 'en';
      expect(noticeText('Today · 07 Nov'), 'Today · 07 Nov');
      language.value = 'ny';
      expect(noticeText('Today · 07 Nov'), 'Lero · 07 Nov');
      expect(noticeText(null), '');
    });
  });

  group('vehicleKind picks the drawing for a category', () {
    test('seaters', () {
      expect(vehicleKind('7 Seater'), 'seater7');
      expect(vehicleKind('Sienta'), 'seater7');
      expect(vehicleKind('5 Seater'), 'seater5');
    });
    test('goods and buses', () {
      expect(vehicleKind('Matola'), 'matola');
      expect(vehicleKind('Minibus'), 'minibus');
      expect(vehicleKind('Pickup'), 'pickup');
      expect(vehicleKind('Truck'), 'truck');
    });
    test('unknown or missing categories get the matola drawing', () {
      expect(vehicleKind(null), 'matola');
      expect(vehicleKind('Something new'), 'matola');
    });
  });
}
