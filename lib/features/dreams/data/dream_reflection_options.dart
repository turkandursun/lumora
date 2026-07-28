/// Canonical answer keys for the reflection flow's quick-select questions
/// (see `DreamReflectionScreen`). Locale-independent — presentation code
/// resolves these to localized chip labels (`dreamFeelingLabels` /
/// `dreamFamiliarPersonLabels` in `dream_reflection_screen.dart`).
class DreamFeelingKeys {
  DreamFeelingKeys._();

  static const peaceful = 'peaceful';
  static const anxious = 'anxious';
  static const confused = 'confused';
  static const happy = 'happy';
  static const sad = 'sad';
  static const neutral = 'neutral';

  static const values = [peaceful, anxious, confused, happy, sad, neutral];
}

class DreamFamiliarPersonKeys {
  DreamFamiliarPersonKeys._();

  static const yes = 'yes';
  static const no = 'no';
  static const notSure = 'notSure';

  static const values = [yes, no, notSure];
}
