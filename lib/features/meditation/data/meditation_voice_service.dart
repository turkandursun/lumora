import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/meditation_voices.dart';

/// Calls ElevenLabs directly from the app (free-plan approach) to synthesize a
/// meditation line, returning the mp3 bytes. Results are cached in memory for
/// the session so repeated lines don't spend extra ElevenLabs characters.
///
/// Returns null on any failure (no key, network error, quota/paid-voice 402…)
/// so the caller can fall back to the device's built-in text-to-speech.
class MeditationVoiceService {
  final Map<String, Uint8List> _cache = {};

  Future<Uint8List?> voiceBytes(String text, {required String voiceId}) async {
    if (elevenLabsApiKey.isEmpty) return null;
    final cacheKey = '$voiceId::$text';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;
    try {
      final res = await http.post(
        Uri.parse(
          'https://api.elevenlabs.io/v1/text-to-speech/$voiceId?output_format=mp3_44100_128',
        ),
        headers: {
          'xi-api-key': elevenLabsApiKey,
          'content-type': 'application/json',
          'accept': 'audio/mpeg',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.6,
            'similarity_boost': 0.75,
            'style': 0.0,
            'use_speaker_boost': true,
            'speed': 0.85, // a touch slower — calmer for meditation
          },
        }),
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _cache[cacheKey] = res.bodyBytes;
        return res.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
