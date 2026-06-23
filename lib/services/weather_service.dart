import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const _geoBase = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _forecastBase = 'https://api.open-meteo.com/v1/forecast';
  static const _timeout = Duration(seconds: 15);

  Future<WeatherData> fetchByCity(String cityName) async {
    // 1 — Geocoding
    final geoUri = Uri.parse(
        '$_geoBase?name=${Uri.encodeComponent(cityName)}&count=1&language=pt&format=json');
    final geoResp = await http.get(geoUri).timeout(_timeout);

    if (geoResp.statusCode != 200) {
      throw Exception('Erro ao buscar localização (${geoResp.statusCode}).');
    }

    final geoBody =
        jsonDecode(utf8.decode(geoResp.bodyBytes)) as Map<String, dynamic>;
    final results = geoBody['results'] as List?;
    if (results == null || results.isEmpty) {
      throw Exception('Cidade "$cityName" não encontrada.');
    }

    final place = results.first as Map<String, dynamic>;
    final lat = (place['latitude'] as num).toDouble();
    final lon = (place['longitude'] as num).toDouble();
    final name = place['name'] as String? ?? cityName;

    // 2 — Previsão
    final forecastUri = Uri.parse(
      '$_forecastBase?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,weathercode,windspeed_10m,precipitation,relative_humidity_2m'
      '&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum'
      '&timezone=auto&forecast_days=4',
    );
    final fResp = await http.get(forecastUri).timeout(_timeout);

    if (fResp.statusCode != 200) {
      throw Exception('Erro ao buscar previsão (${fResp.statusCode}).');
    }

    final fBody =
        jsonDecode(utf8.decode(fResp.bodyBytes)) as Map<String, dynamic>;
    final current = WeatherCurrent.fromJson(
        fBody['current'] as Map<String, dynamic>);

    final daily = fBody['daily'] as Map<String, dynamic>;
    final dates = (daily['time'] as List).cast<String>();
    final codes = (daily['weathercode'] as List).cast<int>();
    final maxTemps = (daily['temperature_2m_max'] as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final minTemps = (daily['temperature_2m_min'] as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final precip = (daily['precipitation_sum'] as List)
        .map((v) => (v as num).toDouble())
        .toList();

    // Pula o dia atual (já está em `current`), exibe os próximos 3
    final forecast = <WeatherDay>[];
    for (var i = 1; i < dates.length && i <= 3; i++) {
      forecast.add(WeatherDay(
        date: DateTime.parse(dates[i]),
        code: codes[i],
        tempMax: maxTemps[i],
        tempMin: minTemps[i],
        precipitationSum: precip[i],
      ));
    }

    return WeatherData(
      city: name,
      latitude: lat,
      longitude: lon,
      current: current,
      forecast: forecast,
      fetchedAt: DateTime.now(),
    );
  }
}
