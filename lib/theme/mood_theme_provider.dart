import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mood_gradients.dart';

/// The currently selected mood for background theming — nullable, and
/// intentionally session-only: it starts at `null` (rendered as the
/// calm/default gradient) every app launch. Whether a picked mood should
/// ever persist across sessions, or feed into anything beyond the
/// background, is a separate decision we haven't made yet.
final moodThemeProvider = StateProvider<AppMood?>((ref) => null);
