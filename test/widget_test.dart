import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy/l10n/app_strings.dart';

void main() {
  test('opening times are formatted in English and Arabic', () {
    const AppStrings en = AppStrings(false);
    const AppStrings ar = AppStrings(true);

    expect(en.clock(9 * 60 + 30), '9:30 AM');
    expect(en.clock(22 * 60 + 30), '10:30 PM');
    expect(ar.clock(9 * 60 + 30), '9:30 ص');
    expect(ar.clock(22 * 60 + 30), '10:30 م');
  });
}
