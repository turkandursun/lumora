import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/services/crisis_detection_service.dart';

void main() {
  group('containsCrisisLanguage', () {
    test('detects direct English expressions of suicidal intent', () {
      expect(CrisisDetectionService.containsCrisisLanguage('I want to kill myself'), isTrue);
      expect(CrisisDetectionService.containsCrisisLanguage('honestly I just want to die'), isTrue);
      expect(
        CrisisDetectionService.containsCrisisLanguage('sometimes I think about suicide'),
        isTrue,
      );
      expect(CrisisDetectionService.containsCrisisLanguage("I don't want to live anymore"), isTrue);
    });

    test('detects direct Turkish expressions of suicidal intent', () {
      expect(CrisisDetectionService.containsCrisisLanguage('artık yaşamak istemiyorum'), isTrue);
      expect(
        CrisisDetectionService.containsCrisisLanguage('bazen intihar etmeyi düşünüyorum'),
        isTrue,
      );
      expect(CrisisDetectionService.containsCrisisLanguage('canıma kıymak istiyorum'), isTrue);
    });

    test('is case-insensitive, including Turkish dotted capital İ', () {
      expect(CrisisDetectionService.containsCrisisLanguage('İNTİHAR etmeyi düşünüyorum'), isTrue);
      expect(CrisisDetectionService.containsCrisisLanguage('I WANT TO DIE'), isTrue);
    });

    test('does not trigger on ordinary difficult emotions', () {
      expect(CrisisDetectionService.containsCrisisLanguage('bugün çok üzgünüm'), isFalse);
      expect(CrisisDetectionService.containsCrisisLanguage('I feel so sad and tired today'), isFalse);
      expect(
        CrisisDetectionService.containsCrisisLanguage('work has been stressing me out lately'),
        isFalse,
      );
      expect(CrisisDetectionService.containsCrisisLanguage('bu sınav beni öldürüyor'), isFalse);
    });

    test('handles empty and blank input', () {
      expect(CrisisDetectionService.containsCrisisLanguage(''), isFalse);
      expect(CrisisDetectionService.containsCrisisLanguage('   '), isFalse);
    });
  });
}
