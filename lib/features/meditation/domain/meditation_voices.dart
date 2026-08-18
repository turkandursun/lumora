/// The named guide voices the user can pick for meditation, each mapped to an
/// ElevenLabs voice id.
///
/// SECURITY NOTE: [elevenLabsApiKey] is embedded in the app (per the chosen
/// free-plan "call ElevenLabs directly from the app" approach). This is fine
/// for a demo/staj build but NOT for a public production release, since anyone
/// can extract it from the app. Move to the server (Edge Function) with a paid
/// ElevenLabs plan before shipping widely.
///
/// Paste your ElevenLabs API key below (from elevenlabs.io → Settings → API
/// Key). While it's empty, meditation just uses the device's built-in voice.
// Voice guidance was removed from meditation, so no ElevenLabs key ships in
// the app anymore. Left empty on purpose.
const String elevenLabsApiKey = '';

class MeditationVoiceOption {
  const MeditationVoiceOption({
    required this.key,
    required this.name,
    required this.voiceId,
  });

  final String key;
  final String name;
  final String voiceId;
}

// Testing with ElevenLabs' built-in default voices (present on every account)
// to rule out "voice not found (404)". Your picks were:
//   Deniz -> ljX1ZrXuDIIRVcmiVSyR, Işık -> g6xIsTj2HwM6VR4iXFCw
// If the defaults below work, those voices just need to be added to your
// account under "My Voices" first (or they require a paid plan).
const List<MeditationVoiceOption> meditationVoiceOptions = [
  MeditationVoiceOption(
      key: 'deniz', name: 'Yıldız', voiceId: 'EXAVITQu4vr4xnSDxMaL'), // Sarah (female)
  MeditationVoiceOption(
      key: 'isik', name: 'Evren', voiceId: 'pNInz6obpgDQGcFmaJgB'), // Adam (male)
];

String voiceIdForKey(String key) => meditationVoiceOptions
    .firstWhere((v) => v.key == key, orElse: () => meditationVoiceOptions.first)
    .voiceId;
