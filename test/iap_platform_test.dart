import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinball/services/iap_service.dart';

void main() {
  test('iOS maps to the single Gold Star product', () {
    expect(PinballStore.productIdsFor(TargetPlatform.iOS), {'pinballstar'});
    expect(PinballStore.starId, 'pinballstar');
  });
  test('Android maps to coffee + chocolate only', () {
    expect(PinballStore.productIdsFor(TargetPlatform.android),
        {'pinballcoffee', 'pinballchocolate'});
    expect(PinballStore.productIdsFor(TargetPlatform.android),
        isNot(contains('pinballstar')));
  });
}
