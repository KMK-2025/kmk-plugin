import 'package:flutter_test/flutter_test.dart';
import 'package:__APP__/shared/utils/version.dart';

void main() {
  group('compareVersions', () {
    test('يقارن الأرقام لا النصوص', () {
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('1.2.0', '1.2.0'), 0);
      expect(compareVersions('1.1.9', '1.2.0'), lessThan(0));
    });

    test('يتجاهل رقم البناء واللواحق', () {
      expect(compareVersions('1.2.0+7', '1.2.0'), 0);
      expect(compareVersions('2.0.0-beta', '2.0.0'), 0);
    });

    test('يكمل الأجزاء الناقصة بأصفار', () {
      expect(compareVersions('2', '2.0.0'), 0);
    });
  });

  group('isVersionSupported', () {
    test('مدعوم عند غياب حد أدنى', () {
      expect(isVersionSupported('0.1.0', null), isTrue);
      expect(isVersionSupported('0.1.0', ''), isTrue);
    });

    test('غير مدعوم إن كان أقدم من الحد الأدنى', () {
      expect(isVersionSupported('1.0.0', '1.2.0'), isFalse);
      expect(isVersionSupported('1.2.0', '1.2.0'), isTrue);
    });
  });
}
