import 'package:flutter_test/flutter_test.dart';
import 'package:smartquail_app/services/history_service.dart';

void main() {
  group('HistoryData.isValid', () {
    test('returns true for valid sensor data', () {
      final data = HistoryData(
        time: '14:30',
        temperature: 28.0,
        humidity: 65.0,
        ammonia: 15.0,
        thi: 74.0,
        fan: false,
        pump: false,
      );
      expect(data.isValid, isTrue);
    });

    test('returns false when temperature is zero (sensor not ready)', () {
      final data = HistoryData(
        time: '14:30',
        temperature: 0.0,
        humidity: 65.0,
        ammonia: 15.0,
        thi: 74.0,
        fan: false,
        pump: false,
      );
      expect(data.isValid, isFalse);
    });

    test('returns false when humidity is zero', () {
      final data = HistoryData(
        time: '14:30',
        temperature: 28.0,
        humidity: 0.0,
        ammonia: 15.0,
        thi: 74.0,
        fan: false,
        pump: false,
      );
      expect(data.isValid, isFalse);
    });

    test('returns false when thi is zero', () {
      final data = HistoryData(
        time: '14:30',
        temperature: 28.0,
        humidity: 65.0,
        ammonia: 15.0,
        thi: 0.0,
        fan: false,
        pump: false,
      );
      expect(data.isValid, isFalse);
    });

    test('returns false when temperature exceeds max (60C)', () {
      final data = HistoryData(
        time: '14:30',
        temperature: 65.0,
        humidity: 65.0,
        ammonia: 15.0,
        thi: 74.0,
        fan: false,
        pump: false,
      );
      expect(data.isValid, isFalse);
    });

    test('returns true when all values are within valid range', () {
      final data = HistoryData(
        time: '12:00',
        temperature: 30.0,
        humidity: 80.0,
        ammonia: 25.0,
        thi: 78.0,
        fan: true,
        pump: true,
      );
      expect(data.isValid, isTrue);
    });
  });
}
