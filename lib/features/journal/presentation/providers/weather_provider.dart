import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/weather_service.dart';

/// Swap this override in a test/provider container to inject a fake
/// [WeatherService] once a real one exists; production always resolves to
/// [MockWeatherService] today.
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return const MockWeatherService();
});

final weatherReadingProvider = FutureProvider<WeatherReading>((ref) {
  return ref.watch(weatherServiceProvider).currentWeather();
});
