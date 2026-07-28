import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/dreams/data/dream_symbol_keywords.dart';

void main() {
  group('detectDreamSymbols', () {
    test('detects a single English keyword', () {
      expect(detectDreamSymbols('I was flying above the clouds'), {DreamSymbolKeys.flying});
    });

    test('detects a Turkish keyword attached to a suffix', () {
      expect(detectDreamSymbols('Evde kayboldum'), {DreamSymbolKeys.house, DreamSymbolKeys.lost});
    });

    test('detects multiple distinct symbols in one entry', () {
      final result = detectDreamSymbols('There was a snake near the door and a mirror on the wall');
      expect(result, {DreamSymbolKeys.snake, DreamSymbolKeys.door, DreamSymbolKeys.mirror});
    });

    test('returns an empty set when nothing matches', () {
      expect(detectDreamSymbols('Just an ordinary quiet walk'), isEmpty);
    });

    test('is case-insensitive', () {
      expect(detectDreamSymbols('WATER everywhere'), {DreamSymbolKeys.water});
    });
  });
}
