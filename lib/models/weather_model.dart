class WeatherCurrent {
  final double temperature;
  final int code;
  final double windspeed;
  final double precipitation;
  final int humidity;

  const WeatherCurrent({
    required this.temperature,
    required this.code,
    required this.windspeed,
    required this.precipitation,
    required this.humidity,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) => WeatherCurrent(
        temperature: (json['temperature_2m'] as num?)?.toDouble() ?? 0,
        code: json['weathercode'] as int? ?? 0,
        windspeed: (json['windspeed_10m'] as num?)?.toDouble() ?? 0,
        precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0,
        humidity: json['relative_humidity_2m'] as int? ?? 0,
      );
}

class WeatherDay {
  final DateTime date;
  final int code;
  final double tempMax;
  final double tempMin;
  final double precipitationSum;

  const WeatherDay({
    required this.date,
    required this.code,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
  });
}

class WeatherData {
  final String city;
  final double latitude;
  final double longitude;
  final WeatherCurrent current;
  final List<WeatherDay> forecast;
  final DateTime fetchedAt;

  const WeatherData({
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.current,
    required this.forecast,
    required this.fetchedAt,
  });

  /// True quando a condição atual ou próximas 24 h são desfavoráveis para atividades externas.
  bool get isBadWeather =>
      isCodeBad(current.code) ||
      (forecast.isNotEmpty && isCodeBad(forecast.first.code));

  static bool isCodeBad(int code) => code >= 55;

  static String emoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 55) return '🌦️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 86) return '🌨️';
    return '⛈️';
  }

  static String description(int code) {
    if (code == 0) return 'Céu limpo';
    if (code == 1) return 'Predominantemente claro';
    if (code == 2) return 'Parcialmente nublado';
    if (code == 3) return 'Nublado';
    if (code <= 48) return 'Neblina';
    if (code <= 53) return 'Garoa leve';
    if (code <= 55) return 'Garoa';
    if (code <= 67) return 'Chuva';
    if (code <= 77) return 'Neve';
    if (code <= 82) return 'Pancadas de chuva';
    if (code <= 86) return 'Pancadas de neve';
    return 'Tempestade';
  }

  static String shortDay(DateTime d) {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[d.weekday % 7];
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'fetchedAt': fetchedAt.toIso8601String(),
        'current': {
          'temperature': current.temperature,
          'code': current.code,
          'windspeed': current.windspeed,
          'precipitation': current.precipitation,
          'humidity': current.humidity,
        },
        'forecast': forecast
            .map((d) => {
                  'date': d.date.toIso8601String(),
                  'code': d.code,
                  'tempMax': d.tempMax,
                  'tempMin': d.tempMin,
                  'precipitationSum': d.precipitationSum,
                })
            .toList(),
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>;
    final f = (json['forecast'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((d) => WeatherDay(
              date: DateTime.parse(d['date'] as String),
              code: d['code'] as int,
              tempMax: (d['tempMax'] as num).toDouble(),
              tempMin: (d['tempMin'] as num).toDouble(),
              precipitationSum: (d['precipitationSum'] as num).toDouble(),
            ))
        .toList();
    return WeatherData(
      city: json['city'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      current: WeatherCurrent(
        temperature: (c['temperature'] as num).toDouble(),
        code: c['code'] as int,
        windspeed: (c['windspeed'] as num).toDouble(),
        precipitation: (c['precipitation'] as num).toDouble(),
        humidity: c['humidity'] as int,
      ),
      forecast: f,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }
}

// ── Detecção de tarefas sensíveis ao clima ────────────────────────────────────

const kWeatherSensitiveKeywords = [
  'limpeza', 'limpar', 'lavagem', 'lavar',
  'instalação', 'instalar', 'solar', 'painel solar', 'módulo solar',
  'pintura', 'pintar',
  'jardinagem', 'jardim', 'plantar', 'poda',
  'telhado', 'construção', 'obra', 'reforma',
  'terraço', 'varanda', 'externo', 'exterior',
  'piscina', 'churrasco', 'secar roupa',
  'calçada', 'pintura externa',
];

bool isWeatherSensitiveTask(String title, String description) {
  final text = '$title $description'.toLowerCase();
  return kWeatherSensitiveKeywords.any((k) => text.contains(k));
}
