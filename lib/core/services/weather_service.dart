import 'package:flutter/material.dart';

/// Coarse weather conditions the UI knows how to render an icon for.
enum WeatherCondition { sunny, partlyCloudy, cloudy, rainy, snowy }

extension WeatherConditionIcon on WeatherCondition {
  IconData get icon {
    switch (this) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.partlyCloudy:
        return Icons.wb_cloudy_rounded;
      case WeatherCondition.cloudy:
        return Icons.cloud_rounded;
      case WeatherCondition.rainy:
        return Icons.water_drop_rounded;
      case WeatherCondition.snowy:
        return Icons.ac_unit_rounded;
    }
  }
}

/// A single point-in-time weather reading — just enough for the home
/// header's small icon + temperature chip.
class WeatherReading {
  const WeatherReading({required this.condition, required this.temperatureCelsius});

  final WeatherCondition condition;
  final double temperatureCelsius;

  String get roundedTemperature => '${temperatureCelsius.round()}°';
}

/// Seam between the home header and wherever weather data actually comes
/// from. [MockWeatherService] is the only implementation today; swapping in
/// a real provider (e.g. a geolocation + forecast API call) later only
/// means adding another implementation and pointing [weatherServiceProvider]
/// (see `weather_provider.dart`) at it — the header UI never changes.
abstract class WeatherService {
  Future<WeatherReading> currentWeather();
}

/// Static placeholder reading — no network call, no location permission.
/// Good enough to build and test the header layout against until a real
/// weather integration is wired up.
class MockWeatherService implements WeatherService {
  const MockWeatherService();

  @override
  Future<WeatherReading> currentWeather() async {
    return const WeatherReading(
      condition: WeatherCondition.sunny,
      temperatureCelsius: 22,
    );
  }
}
