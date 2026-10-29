import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy/config/opening_hours.dart';

// Pharmacy time, written directly (Thursday 29 Oct 2026 is a Thursday).
DateTime thu(int h, [int m = 0]) => DateTime.utc(2026, 10, 29, h, m);
DateTime fri(int h, [int m = 0]) => DateTime.utc(2026, 10, 30, h, m);
DateTime sat(int h, [int m = 0]) => DateTime.utc(2026, 10, 31, h, m);

void main() {
  group('OpeningHours.at', () {
    test('open during opening hours', () {
      expect(OpeningHours.at(sat(9, 30)).isOpen, isTrue);
      expect(OpeningHours.at(sat(15)).isOpen, isTrue);
      expect(OpeningHours.at(sat(22, 29)).isOpen, isTrue);
    });

    test('before opening it opens later today', () {
      final OpeningState s = OpeningHours.at(sat(9, 29));
      expect(s.isOpen, isFalse);
      expect(s.nextOpening, NextOpening.laterToday);
    });

    test('closing time itself counts as closed, opens tomorrow', () {
      final OpeningState s = OpeningHours.at(sat(22, 30));
      expect(s.isOpen, isFalse);
      expect(s.nextOpening, NextOpening.tomorrow);
      expect(s.opensOnWeekday, DateTime.sunday);
    });

    test('closed all Friday, opens Saturday', () {
      final OpeningState s = OpeningHours.at(fri(12));
      expect(s.isOpen, isFalse);
      expect(s.nextOpening, NextOpening.tomorrow);
      expect(s.opensOnWeekday, DateTime.saturday);
    });

    test('Thursday night skips Friday and opens Saturday', () {
      final OpeningState s = OpeningHours.at(thu(23));
      expect(s.isOpen, isFalse);
      expect(s.nextOpening, NextOpening.laterDay);
      expect(s.opensOnWeekday, DateTime.saturday);
    });
  });

  test('pharmacyNow converts to the pharmacy time zone (UTC+3)', () {
    final DateTime local = OpeningHours.pharmacyNow(
      DateTime.utc(2026, 10, 29, 20),
    );
    expect(local.hour, 23);
    expect(local.weekday, DateTime.thursday);
  });
}
