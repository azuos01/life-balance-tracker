import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/storage_service.dart';

const _kCityKey = 'weather_city';
const _kDataKey = 'weather_data';
const _kRefreshMinutes = 30;

class WeatherProvider extends ChangeNotifier {
  final _service = WeatherService();

  WeatherData? _data;
  String _city = '';
  bool _loading = false;
  String? _error;

  WeatherData? get data => _data;
  String get city => _city;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasData => _data != null;

  Future<void> init() async {
    _city = StorageService.instance.getString(_kCityKey) ?? '';
    final cached = StorageService.instance.getJson(_kDataKey);
    if (cached != null) {
      try {
        _data = WeatherData.fromJson(cached);
      } catch (_) {}
    }

    // Auto-refresh se a cidade estiver configurada e o cache for antigo
    if (_city.isNotEmpty) {
      final shouldRefresh = _data == null ||
          DateTime.now().difference(_data!.fetchedAt).inMinutes >=
              _kRefreshMinutes;
      if (shouldRefresh) {
        await fetch(_city, notify: false);
      }
    }
    notifyListeners();
  }

  Future<void> fetch(String cityName, {bool notify = true}) async {
    _city = cityName.trim();
    _loading = true;
    _error = null;
    if (notify) notifyListeners();

    await StorageService.instance.setString(_kCityKey, _city);

    try {
      _data = await _service.fetchByCity(_city);
      await StorageService.instance.setJson(_kDataKey, _data!.toJson());
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
