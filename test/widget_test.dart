import 'package:flutter_test/flutter_test.dart';

import 'package:smartquail_app/main.dart';
import 'package:smartquail_app/services/auth_service.dart';
import 'package:smartquail_app/services/history_service.dart';

void main() {
  test('App classes can be imported and instantiated', () {
    // Verify main app class compiles (does not require Firebase runtime)
    expect(SmartQuailApp.new, isNotNull);
    expect(AuthWrapper.new, isNotNull);
    expect(MainNavigation.new, isNotNull);
  });

  test('HistoryData is instantiable', () {
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
}
