import 'package:flutter/widgets.dart';

/// Which set of crisis-support resources to surface, based on the
/// device's region rather than the app's display language — a Turkish
/// speaker traveling abroad should see resources for where they actually
/// are, not just their chosen app language.
enum CrisisRegion { turkey, unitedStates, other }

/// Reads the device's country code straight from the platform (not the
/// app's resolved `tr`/`en` locale, which carries no country subtag) so
/// resource selection reflects where the phone actually thinks it is.
/// Falls back to [CrisisRegion.other] — the findahelpline.com link —
/// whenever a country can't be determined.
CrisisRegion detectCrisisRegion() {
  final countryCode =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode?.toUpperCase();
  switch (countryCode) {
    case 'TR':
      return CrisisRegion.turkey;
    case 'US':
      return CrisisRegion.unitedStates;
    default:
      return CrisisRegion.other;
  }
}
