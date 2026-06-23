import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance_tracker/models/weather_model.dart';

void main() {
  // ── WeatherCurrent ────────────────────────────────────────────────────────

  group('WeatherCurrent — fromJson', () {
    test('parseia todos os campos', () {
      final c = WeatherCurrent.fromJson({
        'temperature_2m': 23.5,
        'weathercode': 3,
        'windspeed_10m': 12.0,
        'precipitation': 0.0,
        'relative_humidity_2m': 72,
      });
      expect(c.temperature, 23.5);
      expect(c.code, 3);
      expect(c.windspeed, 12.0);
      expect(c.precipitation, 0.0);
      expect(c.humidity, 72);
    });

    test('campos ausentes usam defaults', () {
      final c = WeatherCurrent.fromJson({});
      expect(c.temperature, 0.0);
      expect(c.code, 0);
      expect(c.windspeed, 0.0);
      expect(c.humidity, 0);
    });
  });

  // ── WeatherData — isCodeBad ───────────────────────────────────────────────

  group('WeatherData.isCodeBad', () {
    test('sol (0) = bom', () => expect(WeatherData.isCodeBad(0), false));
    test('nublado (3) = bom', () => expect(WeatherData.isCodeBad(3), false));
    test('garoa leve (53) = bom', () => expect(WeatherData.isCodeBad(53), false));
    test('garoa densa (55) = ruim', () => expect(WeatherData.isCodeBad(55), true));
    test('chuva (63) = ruim', () => expect(WeatherData.isCodeBad(63), true));
    test('tempestade (95) = ruim', () => expect(WeatherData.isCodeBad(95), true));
  });

  // ── WeatherData — isBadWeather ────────────────────────────────────────────

  group('WeatherData — isBadWeather', () {
    WeatherCurrent current(int code) => WeatherCurrent(
          temperature: 20,
          code: code,
          windspeed: 10,
          precipitation: 0,
          humidity: 60,
        );

    WeatherData data({required int currentCode, int? forecastCode}) => WeatherData(
          city: 'Teste',
          latitude: -23.5,
          longitude: -46.6,
          current: current(currentCode),
          forecast: forecastCode == null
              ? []
              : [
                  WeatherDay(
                    date: DateTime.now(),
                    code: forecastCode,
                    tempMax: 25,
                    tempMin: 18,
                    precipitationSum: 0,
                  )
                ],
          fetchedAt: DateTime.now(),
        );

    test('bom quando atual e previsão são boas', () {
      expect(data(currentCode: 2, forecastCode: 1).isBadWeather, false);
    });

    test('ruim quando atual é ruim', () {
      expect(data(currentCode: 63).isBadWeather, true);
    });

    test('ruim quando previsão é ruim mas atual é boa', () {
      expect(data(currentCode: 2, forecastCode: 80).isBadWeather, true);
    });
  });

  // ── WeatherData — emoji e description ─────────────────────────────────────

  group('WeatherData.emoji', () {
    test('céu limpo → ☀️', () => expect(WeatherData.emoji(0), '☀️'));
    test('parcialmente nublado → ⛅', () => expect(WeatherData.emoji(2), '⛅'));
    test('chuva → 🌧️', () => expect(WeatherData.emoji(63), '🌧️'));
    test('tempestade → ⛈️', () => expect(WeatherData.emoji(95), '⛈️'));
  });

  group('WeatherData.description', () {
    test('código 0 → Céu limpo',
        () => expect(WeatherData.description(0), 'Céu limpo'));
    test('código 3 → Nublado',
        () => expect(WeatherData.description(3), 'Nublado'));
    test('código 63 → Chuva',
        () => expect(WeatherData.description(63), 'Chuva'));
  });

  // ── WeatherData — toJson / fromJson ───────────────────────────────────────

  group('WeatherData — toJson / fromJson', () {
    test('round-trip preserva todos os campos', () {
      final original = WeatherData(
        city: 'São Paulo',
        latitude: -23.5,
        longitude: -46.6,
        current: const WeatherCurrent(
          temperature: 22.5,
          code: 1,
          windspeed: 8.0,
          precipitation: 0.0,
          humidity: 65,
        ),
        forecast: [
          WeatherDay(
            date: DateTime(2026, 6, 22),
            code: 3,
            tempMax: 25.0,
            tempMin: 18.0,
            precipitationSum: 0.0,
          ),
        ],
        fetchedAt: DateTime(2026, 6, 22, 14, 0),
      );

      final json = original.toJson();
      final restored = WeatherData.fromJson(json);

      expect(restored.city, original.city);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.current.temperature, original.current.temperature);
      expect(restored.current.code, original.current.code);
      expect(restored.current.humidity, original.current.humidity);
      expect(restored.forecast.length, 1);
      expect(restored.forecast.first.code, 3);
      expect(restored.forecast.first.tempMax, 25.0);
      expect(restored.fetchedAt, original.fetchedAt);
    });
  });

  // ── shortDay ──────────────────────────────────────────────────────────────

  group('WeatherData.shortDay', () {
    test('domingo = Dom', () {
      // weekday 7 = Sunday
      expect(WeatherData.shortDay(DateTime(2026, 6, 21)), 'Dom');
    });

    test('segunda = Seg', () {
      // weekday 1 = Monday
      expect(WeatherData.shortDay(DateTime(2026, 6, 22)), 'Seg');
    });
  });

  // ── isWeatherSensitiveTask ────────────────────────────────────────────────

  group('isWeatherSensitiveTask', () {
    test('detecta "limpeza"', () {
      expect(isWeatherSensitiveTask('Limpeza do telhado', ''), true);
    });

    test('detecta "módulo solar" na descrição', () {
      expect(
          isWeatherSensitiveTask('Tarefa', 'Instalar módulo solar'), true);
    });

    test('detecta "jardinagem"', () {
      expect(isWeatherSensitiveTask('Jardinagem do quintal', ''), true);
    });

    test('não detecta tarefa interna', () {
      expect(isWeatherSensitiveTask('Reunião de equipe', 'online'), false);
    });

    test('case insensitive (maiúsculo)', () {
      expect(isWeatherSensitiveTask('PINTURA da fachada', ''), true);
    });
  });
}
