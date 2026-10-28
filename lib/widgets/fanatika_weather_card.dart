// Fanatika additions to Arc Launcher — GPL-3.0-or-later.
// Uses Open-Meteo's public geocoding and weather APIs; no location permission.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/flauncher_channel.dart';

class FanatikaWeatherCard extends StatefulWidget {
  final String city;
  final bool fahrenheit;
  final bool autoLocation;
  final int days;
  final int refreshMinutes;
  final bool expandVertical;
  const FanatikaWeatherCard({super.key, required this.city, required this.fahrenheit,
    this.autoLocation = false, this.days = 3, this.refreshMinutes = 60,
    this.expandVertical = false});
  @override
  State<FanatikaWeatherCard> createState() => _FanatikaWeatherCardState();
}

class _FanatikaWeatherCardState extends State<FanatikaWeatherCard> {
  Timer? _refreshTimer;
  WeatherInfo? _current;
  String? _error;
  DateTime? _readingTime;
  bool _offlineReading = false;
  String? _autoLocationLabel;
  int _requestNumber = 0;
  @override
  void initState() {
    super.initState();
    _fetch();
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant FanatikaWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city || oldWidget.autoLocation != widget.autoLocation || oldWidget.fahrenheit != widget.fahrenheit || oldWidget.days != widget.days) {
      setState(() { _current = null; _error = null; _readingTime = null; _offlineReading = false; });
      _fetch();
    }
    if (oldWidget.refreshMinutes != widget.refreshMinutes) _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(minutes: widget.refreshMinutes.clamp(30, 180).toInt()), (_) => _fetch());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _requestNumber++;
    super.dispose();
  }

  String get _cacheKey => 'fanatika_weather_cache_${widget.autoLocation ? 'automatic' : widget.city.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${widget.fahrenheit}_${widget.days}';

  Future<void> _readOfflineCache(int request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.length > 12000) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final savedAt = DateTime.tryParse(decoded['savedAt']?.toString() ?? '');
      if (savedAt == null) return;
      final weather = WeatherInfo.fromJson(decoded['weather']);
      if (weather == null || !mounted || request != _requestNumber) return;
      if (_current == null) setState(() {
        _current = weather; _readingTime = savedAt; _offlineReading = true;
      });
    } catch (_) { /* A malformed cache never prevents weather display. */ }
  }

  Future<void> _saveOfflineCache(WeatherInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey,
        jsonEncode({'savedAt': DateTime.now().toUtc().toIso8601String(), 'weather': info.toJson()}));
    } catch (_) { /* Caching is best-effort and never blocks the widget. */ }
  }

  Future<void> _fetch() async {
    final request = ++_requestNumber;
    if (_current == null) await _readOfflineCache(request);
    try {
      WeatherInfo data;
      if (widget.autoLocation) {
        // Read location only when the user opted in. A denied/unsupported fix
        // falls back to the manually selected city without guessing from IP.
        final fix = await FLauncherChannel().fanatikaApproximateLocation();
        final lat = fix['latitude'];
        final lon = fix['longitude'];
        if (fix['ok'] == true && lat is num && lon is num) {
          data = await fetchWeatherByCoordinates(lat.toDouble(), lon.toDouble(), widget.fahrenheit, widget.days);
          _autoLocationLabel = 'Current location (approximate)';
        } else {
          data = await fetchWeather(widget.city, widget.fahrenheit, widget.days);
          _autoLocationLabel = null;
        }
      } else {
        _autoLocationLabel = null;
        data = await fetchWeather(widget.city, widget.fahrenheit, widget.days);
      }
      if (!mounted || request != _requestNumber) return;
      setState(() { _current = data; _error = null; _offlineReading = false; _readingTime = DateTime.now(); });
      _saveOfflineCache(data);
    } catch (_) {
      if (!mounted || request != _requestNumber) return;
      setState(() { _error = _current == null ? 'Weather unavailable' : null; _offlineReading = _current != null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = _current;
    final unit = widget.fahrenheit ? '°F' : '°C';
    return Container(
      width: 268,
      height: widget.expandVertical ? double.infinity : null,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: widget.expandVertical ? MainAxisSize.max : MainAxisSize.min,
        children: [
        Text(_autoLocationLabel ?? widget.city, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 7),
        if (w != null) ...[
          Row(children: [
            Icon(iconForWeather(w.code), size: 39, color: const Color(0xFFFFD36D)),
            const SizedBox(width: 10),
            Text('${w.temperature.round()}$unit',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
          Text(weatherDescription(w.code), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text('H ${w.maximum.round()}°  ·  L ${w.minimum.round()}°',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (w.forecast.isNotEmpty) ...[
            if (widget.expandVertical) const Spacer(),
            const Divider(color: Colors.white24, height: 20),
            Wrap(spacing: 12, runSpacing: 6, alignment: WrapAlignment.center,
              children: w.forecast.map((day) => SizedBox(width: 58, child: Column(children: [
                Text(DateFormat('EEE').format(day.day),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Icon(iconForWeather(day.code), color: const Color(0xFFFFD36D), size: 20),
                Text('${day.high.round()}°/${day.low.round()}°',
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
              ]))).toList(),
            ),
          ],
        ] else Text(_error ?? 'Loading weather…', style: const TextStyle(color: Colors.white70, fontSize: 15)),
        if (_offlineReading && w != null)
          Text('Offline forecast · last updated ${_readingTime == null ? 'previously' : DateFormat('MMM d, HH:mm').format(_readingTime!.toLocal())}',
            style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
      ]),
    );
  }
}

class WeatherInfo {
  final double temperature, maximum, minimum;
  final int code;
  final List<DayForecast> forecast;
  WeatherInfo(this.temperature, this.maximum, this.minimum, this.code, this.forecast);

  Map<String, dynamic> toJson() => {
    'temperature': temperature, 'maximum': maximum, 'minimum': minimum,
    'code': code, 'forecast': forecast.map((d) => d.toJson()).toList(),
  };
  static WeatherInfo? fromJson(Object? input) {
    if (input is! Map) return null;
    try {
      final list = (input['forecast'] as List).take(5);
      return WeatherInfo(
        (input['temperature'] as num).toDouble(), (input['maximum'] as num).toDouble(),
        (input['minimum'] as num).toDouble(), (input['code'] as num).toInt(),
        list.map((v) => DayForecast.fromJson(v)).whereType<DayForecast>().toList(),
      );
    } catch (_) { return null; }
  }
}

class DayForecast {
  final DateTime day;
  final double high, low;
  final int code;
  DayForecast(this.day, this.high, this.low, this.code);
  Map<String, dynamic> toJson() => {
    'day': day.toIso8601String(), 'high': high, 'low': low, 'code': code,
  };
  static DayForecast? fromJson(Object? input) {
    if (input is! Map) return null;
    try {
      final d = DateTime.tryParse(input['day'].toString());
      if (d == null) return null;
      return DayForecast(d, (input['high'] as num).toDouble(),
        (input['low'] as num).toDouble(), (input['code'] as num).toInt());
    } catch (_) { return null; }
  }
}

Future<WeatherInfo> fetchWeather(String city, bool fahrenheit, [int days = 3]) async {
  final geoUri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
    'name': city, 'count': '1', 'language': 'en', 'format': 'json'
  });
  final geo = await http.get(geoUri).timeout(const Duration(seconds: 8));
  if (geo.statusCode != 200) throw const FormatException('Geocoding unavailable');
  final results = (jsonDecode(geo.body) as Map<String, dynamic>)['results'] as List<dynamic>?;
  if (results == null || results.isEmpty) throw const FormatException('City not found');
  final location = results.first as Map<String, dynamic>;
  return fetchWeatherByCoordinates(
    (location['latitude'] as num).toDouble(),
    (location['longitude'] as num).toDouble(), fahrenheit, days);
}

Future<WeatherInfo> fetchWeatherByCoordinates(double latitude, double longitude, bool fahrenheit, [int days = 3]) async {
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw const FormatException('Invalid weather coordinates');
  }
  final weatherUri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '$latitude',
    'longitude': '$longitude',
    'current': 'temperature_2m,weather_code',
    'daily': 'temperature_2m_max,temperature_2m_min,weather_code',
    'temperature_unit': fahrenheit ? 'fahrenheit' : 'celsius',
    'forecast_days': '${days.clamp(1, 5)}', 'timezone': 'auto',
  });
  final reply = await http.get(weatherUri).timeout(const Duration(seconds: 8));
  if (reply.statusCode != 200) throw const FormatException('Weather unavailable');
  final payload = jsonDecode(reply.body) as Map<String, dynamic>;
  final now = payload['current'] as Map<String, dynamic>;
  final day = payload['daily'] as Map<String, dynamic>;
  final dates = day['time'] as List;
  final highs = day['temperature_2m_max'] as List;
  final lows = day['temperature_2m_min'] as List;
  final codes = day['weather_code'] as List;
  final forecast = <DayForecast>[];
  for (var i = 0; i < dates.length; i++) {
    forecast.add(DayForecast(
      DateTime.parse(dates[i] as String),
      (highs[i] as num).toDouble(),
      (lows[i] as num).toDouble(),
      (codes[i] as num).toInt(),
    ));
  }
  return WeatherInfo(
    (now['temperature_2m'] as num).toDouble(),
    (highs.first as num).toDouble(),
    (lows.first as num).toDouble(),
    (now['weather_code'] as num).toInt(),
    forecast,
  );
}

IconData iconForWeather(int code) => code <= 1 ? Icons.wb_sunny_outlined
    : code <= 3 ? Icons.cloud_queue
    : code <= 48 ? Icons.cloud_outlined
    : code <= 67 ? Icons.grain
    : code <= 77 ? Icons.ac_unit
    : code <= 82 ? Icons.water_drop_outlined
    : code <= 86 ? Icons.ac_unit : Icons.thunderstorm_outlined;

String weatherDescription(int code) {
  if (code == 0) return 'Clear';
  if (code <= 3) return 'Partly cloudy';
  if (code <= 48) return 'Fog';
  if (code <= 67) return 'Rain';
  if (code <= 77) return 'Snow';
  if (code <= 82) return 'Showers';
  if (code <= 86) return 'Snow showers';
  return 'Thunderstorms';
}
