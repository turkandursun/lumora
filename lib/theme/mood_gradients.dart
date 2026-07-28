import 'package:flutter/material.dart';

import 'lumora_palette.dart';

/// The five moods a journal entry can be tagged with, and the visual
/// language each one drives on mood-aware backgrounds.
enum AppMood { happy, calm, tired, sad, anxious }

/// Weather-style symbol for each mood, in [AppMood] order
/// (happy, calm, tired, sad, anxious). Shared by the welcome mood picker
/// and the calendar, so a day's mood reads the same everywhere.
const List<IconData> moodSymbolIcons = [
  Icons.wb_sunny_rounded, // happy -> sun
  Icons.cloud_rounded, // calm -> soft cloud
  Icons.nightlight_round, // tired -> moon
  Icons.grain_rounded, // sad -> rain
  Icons.air_rounded, // anxious -> wind
];

/// Solid accent colour for each mood, in [AppMood] order.
const List<Color> moodSymbolColors = [
  Color(0xFFF4C95D), // happy
  Color(0xFF9FD8B0), // calm
  Color(0xFFB9A7E0), // tired
  Color(0xFF8FA9D9), // sad
  Color(0xFFE59BB0), // anxious
];

/// Maps each [AppMood] to a background gradient — hue/brightness/contrast
/// shifts within Lumora's existing night-sky-to-purple palette family, so
/// every mood still reads as the same app, just a different emotional
/// register of it.
class MoodGradients {
  MoodGradients._();

  /// Shared stop positions for every mood gradient, so [AnimatedContainer]
  /// can lerp smoothly between them (matching stop counts is required for
  /// Flutter to interpolate colors rather than cross-fading two gradients).
  static const List<double> stops = [0.0, 0.42, 0.72, 1.0];

  /// Calm is Lumora's serene, steady default — unchanged from the existing
  /// night-sky auth gradient.
  static const List<Color> _calm = LumoraPalette.backgroundGradient;

  /// Happy — brighter, warmer, leaning into the brand's pink accents with
  /// a touch more glow.
  static const List<Color> _happy = [
    Color(0xFF2E1A3D),
    Color(0xFF7A3F8F),
    Color(0xFFD46FAE),
    Color(0xFFF9A8D4),
  ];

  /// Tired — deeper, dimmer, more navy/muted purple; low vibrancy and
  /// soft contrast, gentle rather than alarming.
  static const List<Color> _tired = [
    Color(0xFF12101F),
    Color(0xFF1C1830),
    Color(0xFF282142),
    Color(0xFF3D3560),
  ];

  /// Sad — cooler, deeper blue-purple, slightly desaturated, but keeps
  /// enough violet warmth to feel understanding rather than clinical.
  static const List<Color> _sad = [
    Color(0xFF141227),
    Color(0xFF201C42),
    Color(0xFF2E2F63),
    Color(0xFF4A4E8A),
  ];

  /// Anxious — muted and softened, with a narrower value range between
  /// stops so contrast stays low and nothing reads as sharp or saturated.
  static const List<Color> _anxious = [
    Color(0xFF211C34),
    Color(0xFF2F2A48),
    Color(0xFF3D3759),
    Color(0xFF4C4568),
  ];

  static const Map<AppMood, List<Color>> _gradients = {
    AppMood.happy: _happy,
    AppMood.calm: _calm,
    AppMood.tired: _tired,
    AppMood.sad: _sad,
    AppMood.anxious: _anxious,
  };

  /// The gradient for [mood], falling back to the calm/default gradient
  /// when no mood has been selected yet.
  static List<Color> forMood(AppMood? mood) => _gradients[mood ?? AppMood.calm]!;
}
