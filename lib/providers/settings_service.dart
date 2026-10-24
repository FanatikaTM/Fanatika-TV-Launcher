/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';

import 'package:flauncher/providers/reddit_slideshow.dart';
import 'package:flauncher/providers/unsplash_slideshow.dart';
import 'package:flauncher/widgets/settings/back_button_actions.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

const _appHighlightAnimationEnabledKey = "app_highlight_animation_enabled";
const _appKeyClickEnabledKey = "app_key_click_enabled";
const _autoHideAppBar = "auto_hide_app_bar";
const _hideStatusBarInGrid = "hide_status_bar_in_grid";
const _gradientUuidKey = "gradient_uuid";
const _backButtonAction = "back_button_action";
const _dateFormat = "date_format";
const _showCategoryTitles = "show_category_titles";
const _showAppNamesBelowIcons = "show_app_names_below_icons";
const _showDateInStatusBar = "show_date_in_status_bar";
const _showTimeInStatusBar = "show_time_in_status_bar";
const _timeFormat = "time_format";
const _wifiUsagePeriod = "wifi_usage_period";
const _showWifiWidgetInStatusBar = "show_wifi_widget_in_status_bar";
const String _showNetworkIndicatorInStatusBar = "show_network_indicator_in_status_bar";
const String _accentColor = "accent_color";
const String _screensaverClockStyle = "screensaver_clock_style";
const String _dockBackdropFilterDisabled = "dock_backdrop_filter_disabled";
const String _backgroundBlurDisabled = "background_blur_disabled";
const String _showWatchNextSection = "show_watch_next_section";
const String _dockDarkBackground = "dock_dark_background";
const String _dockShadowEnabled = "dock_shadow_enabled";
const String _showFocusBorders = "show_focus_borders";
const String _focusBorderThickness = "focus_border_thickness";

// Focus border thickness options (in dp)
const double FOCUS_BORDER_THIN = 1.0;
const double FOCUS_BORDER_DEFAULT = 1.5;
const double FOCUS_BORDER_MEDIUM = 2.0;
const double FOCUS_BORDER_BOLD = 3.0;

const List<double> FOCUS_BORDER_THICKNESS_OPTIONS = [
  FOCUS_BORDER_THIN,
  FOCUS_BORDER_DEFAULT,
  FOCUS_BORDER_MEDIUM,
  FOCUS_BORDER_BOLD,
];

// WiFi usage period options
const String WIFI_USAGE_DAILY = "daily";
const String WIFI_USAGE_WEEKLY = "weekly";
const String WIFI_USAGE_MONTHLY = "monthly";

// Accent color presets (hex values)
const String ACCENT_COLOR_PURPLE = "7C4DFF";
const String ACCENT_COLOR_TEAL = "00BFA5";
const String ACCENT_COLOR_BLUE = "2979FF";
const String ACCENT_COLOR_ORANGE = "FF6D00";
const String ACCENT_COLOR_PINK = "F50057";
const String ACCENT_COLOR_GREEN = "00C853";
const String ACCENT_COLOR_WHITE = "FFFFFF";
const String ACCENT_COLOR_YELLOW = "FFD600";
const String ACCENT_COLOR_RED = "D50000";
const String ACCENT_COLOR_CYAN = "00E5FF";
const String ACCENT_COLOR_INDIGO = "536DFE";
const String ACCENT_COLOR_LIME = "AEEA00";
const String ACCENT_COLOR_AMBER = "FFAB00";
const String ACCENT_COLOR_ROSE = "FF4081";
const String ACCENT_COLOR_ICE_BLUE = "80D8FF";

class SettingsService extends ChangeNotifier {
  static final defaultDateFormat = "EEEE d";
  static final defaultTimeFormat = "H:mm";
  final SharedPreferences _sharedPreferences;

  bool get appHighlightAnimationEnabled =>
      showFocusBorders && (_sharedPreferences.getBool(_appHighlightAnimationEnabledKey) ?? false);

  bool get appKeyClickEnabled => _sharedPreferences.getBool(_appKeyClickEnabledKey) ?? true;

  bool get autoHideAppBarEnabled => _sharedPreferences.getBool(_autoHideAppBar) ?? false;

  bool get hideStatusBarInGrid => _sharedPreferences.getBool(_hideStatusBarInGrid) ?? false;

  bool get showCategoryTitles => _sharedPreferences.getBool(_showCategoryTitles) ?? false;

  bool get showAppNamesBelowIcons => _sharedPreferences.getBool(_showAppNamesBelowIcons) ?? false;

  bool get showDateInStatusBar => _sharedPreferences.getBool(_showDateInStatusBar) ?? false;

  bool get showTimeInStatusBar => _sharedPreferences.getBool(_showTimeInStatusBar) ?? true;

  String? get gradientUuid => _sharedPreferences.getString(_gradientUuidKey);

  String get backButtonAction => _sharedPreferences.getString(_backButtonAction) ?? BACK_BUTTON_ACTION_NOTHING;

  String get dateFormat => _sharedPreferences.getString(_dateFormat) ?? defaultDateFormat;

  String get timeFormat => _sharedPreferences.getString(_timeFormat) ?? defaultTimeFormat;

  String get wifiUsagePeriod => _sharedPreferences.getString(_wifiUsagePeriod) ?? WIFI_USAGE_DAILY;

  bool get showWifiWidgetInStatusBar => _sharedPreferences.getBool(_showWifiWidgetInStatusBar) ?? false;

  bool get showNetworkIndicatorInStatusBar => _sharedPreferences.getBool(_showNetworkIndicatorInStatusBar) ?? true;

  String get accentColorHex => _sharedPreferences.getString(_accentColor) ?? ACCENT_COLOR_WHITE;

  String get screensaverClockStyle => _sharedPreferences.getString(_screensaverClockStyle) ?? "minimal";

  bool get dockBackdropFilterDisabled => _sharedPreferences.getBool(_dockBackdropFilterDisabled) ?? false;

  bool get backgroundBlurDisabled => _sharedPreferences.getBool(_backgroundBlurDisabled) ?? false;

  bool get showWatchNextSection => _sharedPreferences.getBool(_showWatchNextSection) ?? false;

  bool get dockDarkBackground => _sharedPreferences.getBool(_dockDarkBackground) ?? false;

  bool get dockShadowEnabled => _sharedPreferences.getBool(_dockShadowEnabled) ?? false;

  bool get showFocusBorders => _sharedPreferences.getBool(_showFocusBorders) ?? true;

  // Fanatika additions; original Arc Favorites and layout data are untouched.
  bool get showFanatikaHero => _sharedPreferences.getBool('fanatika_large_title') ?? true;
  bool get showFanatikaWeather => _sharedPreferences.getBool('fanatika_weather_enabled') ?? true;
  String get fanatikaWeatherCity => _sharedPreferences.getString('fanatika_weather_city') ?? 'Sofia';
  bool get fanatikaFahrenheit => _sharedPreferences.getBool('fanatika_weather_fahrenheit') ?? false;

  Future<void> setShowFanatikaHero(bool value) => set('fanatika_large_title', value);
  Future<void> setShowFanatikaWeather(bool value) => set('fanatika_weather_enabled', value);
  Future<void> setFanatikaFahrenheit(bool value) => set('fanatika_weather_fahrenheit', value);
  Future<void> setFanatikaWeatherCity(String city) async {
    final clean = city.trim();
    if (clean.isEmpty || clean.length > 80) return;
    await _sharedPreferences.setString('fanatika_weather_city', clean);
    notifyListeners();
  }


  // Opt-in public GitHub release checks. Checks run when the app launches/resumes,
  // not as a privileged background service. Off by default.
  static const String fanatikaDefaultReleaseRepo = 'FanatikaTM/Fanatika-TV-Launcher-Releases';
  String get fanatikaReleaseRepo =>
      _sharedPreferences.getString('fanatika_v26_release_repo') ?? fanatikaDefaultReleaseRepo;
  Future<void> setFanatikaReleaseRepo(String repo) async {
    if (!RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(repo) ||
        repo.contains('..') || repo.length > 150) {
      throw ArgumentError('Use owner/repository for a public GitHub release repository');
    }
    await _sharedPreferences.setString('fanatika_v26_release_repo', repo);
    await _sharedPreferences.remove('fanatika_v2_update_success_ms');
    await _sharedPreferences.remove('fanatika_v2_update_attempt_ms');
    await _sharedPreferences.remove('fanatika_v2_update_alerted_tag');
    notifyListeners();
  }
  static const List<int> fanatikaUpdateCadenceChoices = [0, 15, 30];
  int get fanatikaUpdateCheckDays =>
      fanatikaUpdateCadenceChoices.contains(_sharedPreferences.getInt('fanatika_v2_update_days'))
          ? _sharedPreferences.getInt('fanatika_v2_update_days')!
          : 0;
  int get fanatikaUpdateLastSuccessMs =>
      _sharedPreferences.getInt('fanatika_v2_update_success_ms') ?? 0;
  int get fanatikaUpdateLastAttemptMs =>
      _sharedPreferences.getInt('fanatika_v2_update_attempt_ms') ?? 0;
  String get fanatikaUpdateLastAlertedTag =>
      _sharedPreferences.getString('fanatika_v2_update_alerted_tag') ?? '';
  Future<void> setFanatikaUpdateCheckDays(int days) async {
    if (!fanatikaUpdateCadenceChoices.contains(days)) throw ArgumentError('Invalid update cadence');
    await _sharedPreferences.setInt('fanatika_v2_update_days', days);
    notifyListeners();
  }
  // These timestamps are internal bookkeeping and must not rebuild all Favorites.
  Future<void> markFanatikaUpdateAttempt(int timeMs, {required bool success}) async {
    await _sharedPreferences.setInt('fanatika_v2_update_attempt_ms', timeMs);
    if (success) await _sharedPreferences.setInt('fanatika_v2_update_success_ms', timeMs);
  }
  Future<void> markFanatikaUpdateAlerted(String tag) async {
    await _sharedPreferences.setString('fanatika_v2_update_alerted_tag', tag);
  }

  // Fanatika v2 options are namespaced; original Arc preferences stay untouched.
  double get fanatikaHeroSize => (_sharedPreferences.getDouble('fanatika_v2_hero_size') ?? 58.0).clamp(28.0, 96.0).toDouble();
  String get fanatikaHeroPlacement => _sharedPreferences.getString('fanatika_v2_hero_position') ?? 'left';
  String get fanatikaTitleStyle => _sharedPreferences.getString('fanatika_v2_title_style') ?? 'Cinema';
  bool get fanatikaWeatherAutoLocation => _sharedPreferences.getBool('fanatika_v27_auto_weather_location') ?? false;
  bool get fanatikaRecoveryProfileActive => _sharedPreferences.containsKey('fanatika_v23_recovery_snapshot');
  String get fanatikaToolsLanguage => _sharedPreferences.getString('fanatika_v23_tools_language') ?? 'en';
  bool get fanatikaRememberLast => _sharedPreferences.getBool('fanatika_v23_remember_last') ?? false;
  String get fanatikaLastFavorite => _sharedPreferences.getString('fanatika_v23_last_favorite') ?? '';
  Future<void> saveFanatikaLastFavorite(String name) async {
    if (fanatikaRememberLast && name.length <= 200 && fanatikaLastFavorite != name) {
      await _sharedPreferences.setString('fanatika_v23_last_favorite', name);
      // Intentionally no notifyListeners: D-pad focus must not reset during navigation.
    }
  }
  Map<String, String> get fanatikaAppBackgrounds => _v2Map('fanatika_v23_app_backgrounds');
  int get fanatikaForecastDays => (_sharedPreferences.getInt('fanatika_v2_forecast_days') ?? 3).clamp(1, 5).toInt();
  int get fanatikaWeatherRefresh => (_sharedPreferences.getInt('fanatika_v2_weather_refresh') ?? 60).clamp(30, 180).toInt();
  bool get fanatikaPerformance => _sharedPreferences.getBool('fanatika_v2_performance') ?? false;
  // Fanatika v2.5: all additional appearance controls are opt-in and reversible.
  bool get fanatikaCenterSections => _sharedPreferences.getBool('fanatika_v2_center_sections') ?? false;
  bool get fanatikaFocusGrow => _sharedPreferences.getBool('fanatika_v2_focus_grow') ?? true;
  bool get fanatikaFocusGlow => _sharedPreferences.getBool('fanatika_v2_focus_glow') ?? true;
  bool get fanatikaFixedTitle => _sharedPreferences.getBool('fanatika_v2_fixed_title') ?? true;
  String get fanatikaStatusBarStyle => _sharedPreferences.getString('fanatika_v2_bar_style') ?? 'Transparent';
  bool get fanatikaStatusApps => _sharedPreferences.getBool('fanatika_v2_status_apps') ?? false;
  bool get fanatikaStatusSleep => _sharedPreferences.getBool('fanatika_v2_status_sleep') ?? false;
  bool get fanatikaStatusTools => _sharedPreferences.getBool('fanatika_v2_status_tools') ?? false;
  bool get fanatikaStatusWeather => _sharedPreferences.getBool('fanatika_v2_status_weather') ?? false;
  bool get fanatikaFocusAnimations => _sharedPreferences.getBool('fanatika_v2_focus_animations') ?? true;
  bool get fanatikaSmartMountains => _sharedPreferences.getBool('fanatika_v2_smart_mountains') ?? false;
  String get fanatikaLayoutPreset => _sharedPreferences.getString('fanatika_v2_layout_preset') ?? 'Custom';
  double get fanatikaHeroOpacity => (_sharedPreferences.getDouble('fanatika_v2_hero_opacity') ?? 1.0).clamp(0.3, 1.0).toDouble();
  String get fanatikaSettingsPin => _sharedPreferences.getString('fanatika_v2_pin') ?? '';
  int get fanatikaSleepShortcutKey => _sharedPreferences.getInt('fanatika_v2_sleep_shortcut_key') ?? 0;
  Map<String, String> get fanatikaDescriptions => _v2Map('fanatika_v2_descriptions');
  Map<String, String> get fanatikaInputNames => _v2Map('fanatika_v2_input_names');
  String get fanatikaDescriptionFallback => 'Open your favorite app';
  Map<String, String> _v2Map(String key) {
    try {
      final decoded = jsonDecode(_sharedPreferences.getString(key) ?? '{}');
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return {};
  }
  Future<void> setFanatikaOption(String key, Object value) async {
    if (!key.startsWith('fanatika_v2_')) throw ArgumentError('Invalid setting key');
    if (value is bool) { await _sharedPreferences.setBool(key, value); }
    else if (value is int) { await _sharedPreferences.setInt(key, value); }
    else if (value is double) { await _sharedPreferences.setDouble(key, value); }
    else if (value is String) { await _sharedPreferences.setString(key, value); }
    else { throw ArgumentError('Unsupported preference'); }
    notifyListeners();
  }
  Future<void> setFanatikaMapValue(String key, String item, String label) async {
    if (key != 'fanatika_v2_descriptions' && key != 'fanatika_v2_input_names' && key != 'fanatika_v23_app_backgrounds') {
      throw ArgumentError('Invalid map');
    }
    if (item.length > 200 || label.length > 120) throw ArgumentError('Value too long');
    final map = _v2Map(key);
    if (label.trim().isEmpty) { map.remove(item); } else { map[item] = label.trim(); }
    await _sharedPreferences.setString(key, jsonEncode(map));
    notifyListeners();
  }
  Map<String, dynamic> fanatikaExportPreferences() {
    final values = <String, dynamic>{};
    for (final key in _sharedPreferences.getKeys()) {
      // Do not export credentials or a settings PIN into public Downloads.
      final lower = key.toLowerCase();
      if (['password', 'token', 'secret', 'apikey', 'api_key',
            'credential', 'clientid', 'pin', 'auth'].any(lower.contains)) continue;
      final value = _sharedPreferences.get(key);
      if (value is bool || value is int || value is double || value is String || value is List<String>) {
        values[key] = value;
      }
    }
    return values;
  }
  Future<void> fanatikaImportPreferences(Map<String, dynamic> prefs) async {
    if (prefs.length > 500) throw const FormatException('Too many preferences');
    for (final entry in prefs.entries) {
      if (entry.key.length > 160) continue;
      // Never restore a PIN or arbitrary credentials from imported JSON.
      final lower = entry.key.toLowerCase();
      if (['password', 'token', 'secret', 'apikey', 'api_key',
            'credential', 'clientid', 'pin', 'auth'].any(lower.contains)) continue;
      final v = entry.value;
      if (v is bool) { await _sharedPreferences.setBool(entry.key, v); }
      else if (v is int) { await _sharedPreferences.setInt(entry.key, v); }
      else if (v is double) { await _sharedPreferences.setDouble(entry.key, v); }
      else if (v is String && v.length <= 5000) { await _sharedPreferences.setString(entry.key, v); }
      else if (v is List && v.every((e) => e is String && (e as String).length <= 500)) {
        await _sharedPreferences.setStringList(entry.key, v.cast<String>());
      }
    }
    notifyListeners();
  }
  Future<void> setFanatikaLayout(String preset) async {
    if (!['Minimal', 'Cinema', 'Classic'].contains(preset)) throw ArgumentError('Unknown preset');
    await _sharedPreferences.setString('fanatika_v2_layout_preset', preset);
    await _sharedPreferences.setBool('fanatika_large_title', preset != 'Classic');
    await _sharedPreferences.setBool('fanatika_weather_enabled', preset != 'Minimal');
    await _sharedPreferences.setBool('fanatika_v2_focus_animations', preset == 'Cinema');
    await _sharedPreferences.setBool(_backgroundBlurDisabled, preset == 'Minimal');
    await _sharedPreferences.setBool(_dockBackdropFilterDisabled, preset == 'Minimal');
    notifyListeners();
  }
  Future<void> setFanatikaPerformance(bool value) async {
    await _sharedPreferences.setBool('fanatika_v2_performance', value);
    notifyListeners();
  }

  // Manual recovery only. Never changes Android HOME, installs/uninstalls, or clears Arc's Favorites.
  // Only the six visual options below are changed; backup remains private to this app.
  Future<void> enableFanatikaRecoveryProfile() async {
    if (fanatikaRecoveryProfileActive) return;
    const keys = <String>[
      'fanatika_large_title', 'fanatika_weather_enabled',
      'fanatika_v2_focus_animations', 'fanatika_v2_smart_mountains',
      'fanatika_v2_performance', 'fanatika_v2_title_style',
    ];
    final previous = <String, dynamic>{};
    for (final key in keys) {
      if (_sharedPreferences.containsKey(key)) previous[key] = _sharedPreferences.get(key);
    }
    await _sharedPreferences.setString('fanatika_v23_recovery_snapshot', jsonEncode(previous));
    await _sharedPreferences.setBool('fanatika_large_title', false);
    await _sharedPreferences.setBool('fanatika_weather_enabled', false);
    await _sharedPreferences.setBool('fanatika_v2_focus_animations', false);
    await _sharedPreferences.setBool('fanatika_v2_smart_mountains', false);
    await _sharedPreferences.setBool('fanatika_v2_performance', true);
    await _sharedPreferences.setString('fanatika_v2_title_style', 'Classic');
    notifyListeners();
  }

  Future<void> restoreFanatikaRecoveryProfile() async {
    final backup = _sharedPreferences.getString('fanatika_v23_recovery_snapshot');
    if (backup == null) return;
    final parsed = jsonDecode(backup);
    if (parsed is! Map) throw const FormatException('Invalid recovery snapshot');
    const keys = <String>[
      'fanatika_large_title', 'fanatika_weather_enabled',
      'fanatika_v2_focus_animations', 'fanatika_v2_smart_mountains',
      'fanatika_v2_performance', 'fanatika_v2_title_style',
    ];
    for (final key in keys) {
      if (!parsed.containsKey(key)) {
        await _sharedPreferences.remove(key);
      } else if (parsed[key] is bool) {
        await _sharedPreferences.setBool(key, parsed[key] as bool);
      } else if (parsed[key] is String) {
        await _sharedPreferences.setString(key, parsed[key] as String);
      }
    }
    await _sharedPreferences.remove('fanatika_v23_recovery_snapshot');
    notifyListeners();
  }

  double get focusBorderThickness => _sharedPreferences.getDouble(_focusBorderThickness) ?? FOCUS_BORDER_DEFAULT;

  Future<void> setFocusBorderThickness(double value) async {
    await _sharedPreferences.setDouble(_focusBorderThickness, value);
    notifyListeners();
  }

  Color get accentColor {
    final hex = accentColorHex;
    return Color(int.parse("0xFF$hex"));
  }

  SettingsService(this._sharedPreferences);

  Future<void> set(String key, bool value) async {
    await _sharedPreferences.setBool(key, value);
    notifyListeners();
  }

  Future<void> setAppHighlightAnimationEnabled(bool value) async {
    if (value && !showFocusBorders) {
      return;
    }
    return set(_appHighlightAnimationEnabledKey, value);
  }

  Future<void> setAppKeyClickEnabled(bool value) async {
    return set(_appKeyClickEnabledKey, value);
  }

  Future<void> setAutoHideAppBarEnabled(bool value) async {
    return set(_autoHideAppBar, value);
  }

  Future<void> setHideStatusBarInGrid(bool value) async {
    return set(_hideStatusBarInGrid, value);
  }

  Future<void> setGradientUuid(String value) async {
    await _sharedPreferences.setString(_gradientUuidKey, value);
    notifyListeners();
  }

  Future<void> setBackButtonAction(String value) async {
    await _sharedPreferences.setString(_backButtonAction, value);
    notifyListeners();
  }

  Future<void> setDateTimeFormat(String dateFormatString, String timeFormatString) async {
    await Future.wait([
      _sharedPreferences.setString(_dateFormat, dateFormatString),
      _sharedPreferences.setString(_timeFormat, timeFormatString),
    ]);
    notifyListeners();
  }

  Future<void> setShowCategoryTitles(bool show) async {
    return set(_showCategoryTitles, show);
  }

  Future<void> setShowAppNamesBelowIcons(bool show) async {
    return set(_showAppNamesBelowIcons, show);
  }

  Future<void> setShowDateInStatusBar(bool show) async {
    return set(_showDateInStatusBar, show);
  }

  Future<void> setShowTimeInStatusBar(bool show) async {
    return set(_showTimeInStatusBar, show);
  }

  Future<void> setWifiUsagePeriod(String period) async {
    await _sharedPreferences.setString(_wifiUsagePeriod, period);
    notifyListeners();
  }

  Future<void> setShowWifiWidgetInStatusBar(bool show) async {
    return set(_showWifiWidgetInStatusBar, show);
  }

  Future<void> setShowNetworkIndicatorInStatusBar(bool show) async {
    return set(_showNetworkIndicatorInStatusBar, show);
  }

  Future<void> setAccentColor(String colorHex) async {
    await _sharedPreferences.setString(_accentColor, colorHex);
    notifyListeners();
  }

  Future<void> setScreensaverClockStyle(String style) async {
    await _sharedPreferences.setString(_screensaverClockStyle, style);
    notifyListeners();
  }

  Future<void> setDockBackdropFilterDisabled(bool value) async {
    return set(_dockBackdropFilterDisabled, value);
  }

  Future<void> setBackgroundBlurDisabled(bool value) async {
    return set(_backgroundBlurDisabled, value);
  }

  Future<void> setShowWatchNextSection(bool value) async {
    return set(_showWatchNextSection, value);
  }

  Future<void> setDockDarkBackground(bool value) async {
    return set(_dockDarkBackground, value);
  }

  Future<void> setDockShadowEnabled(bool value) async {
    return set(_dockShadowEnabled, value);
  }

  Future<void> setShowFocusBorders(bool value) async {
    await set(_showFocusBorders, value);
    if (!value) {
      await setAppHighlightAnimationEnabled(false);
    }
  }

  bool get timeBasedWallpaperEnabled => _sharedPreferences.getBool("time_based_wallpaper_enabled") ?? false;

  Future<void> setTimeBasedWallpaperEnabled(bool enabled) async {
    await _sharedPreferences.setBool("time_based_wallpaper_enabled", enabled);
    notifyListeners();
  }

  /// Each user brings their own Unsplash API access key (Demo apps are limited to 50 requests/hour).
  String get unsplashAccessKey => _sharedPreferences.getString("unsplash_access_key") ?? "";

  Future<void> setUnsplashAccessKey(String key) async {
    await _sharedPreferences.setString("unsplash_access_key", key.trim());
    if (key.trim().isEmpty) {
      await _sharedPreferences.setBool("unsplash_slideshow_enabled", false);
    }
    notifyListeners();
  }

  /// The slideshow only runs with an access key.
  bool get unsplashSlideshowEnabled =>
      unsplashAccessKey.isNotEmpty && (_sharedPreferences.getBool("unsplash_slideshow_enabled") ?? false);

  static const List<int> unsplashIntervalChoices = [5, 10, 30, 60];

  int get unsplashIntervalMinutes => _sharedPreferences.getInt("unsplash_interval_minutes") ?? 10;

  Future<void> setUnsplashIntervalMinutes(int minutes) async {
    await _sharedPreferences.setInt("unsplash_interval_minutes", minutes);
    notifyListeners();
  }

  /// Slideshow sources: search keywords, "topics:ID,ID" or "collections:ID,ID".
  /// Slideshow category keys (see slideshowSources) used from 6h to 18h, and the rest of the time.
  List<String> get unsplashDaySources =>
      _sharedPreferences.getStringList("unsplash_day_sources") ?? defaultDaySlideshowSources;

  List<String> get unsplashNightSources =>
      _sharedPreferences.getStringList("unsplash_night_sources") ?? defaultNightSlideshowSources;

  Future<void> setUnsplashSources({required bool day, required List<String> keys}) async {
    await _sharedPreferences.setStringList(day ? "unsplash_day_sources" : "unsplash_night_sources", keys);
    notifyListeners();
  }

  Future<void> setUnsplashSlideshowEnabled(bool enabled) async {
    await _sharedPreferences.setBool("unsplash_slideshow_enabled", enabled);
    if (enabled) {
      await _sharedPreferences.setBool("reddit_wallpaper_enabled", false);
    }
    notifyListeners();
  }

  /// Photographer of the slideshow image on screen, kept across restarts for attribution.
  String? get unsplashAuthor => _sharedPreferences.getString("unsplash_author");

  Future<void> setUnsplashAuthor(String author) => _sharedPreferences.setString("unsplash_author", author);

  // Reddit Wallpaper Settings

  bool get redditWallpaperEnabled => _sharedPreferences.getBool("reddit_wallpaper_enabled") ?? false;

  Future<void> setRedditWallpaperEnabled(bool enabled) async {
    await _sharedPreferences.setBool("reddit_wallpaper_enabled", enabled);
    if (enabled) {
      await _sharedPreferences.setBool("unsplash_slideshow_enabled", false);
    }
    notifyListeners();
  }

  static const List<int> redditIntervalChoices = [5, 10, 30, 60, 360, 720, 1440];

  int get redditIntervalMinutes => _sharedPreferences.getInt("reddit_interval_minutes") ?? 10;

  Future<void> setRedditIntervalMinutes(int minutes) async {
    await _sharedPreferences.setInt("reddit_interval_minutes", minutes);
    notifyListeners();
  }

  List<String> get redditSubreddits => _sharedPreferences.getStringList("reddit_subreddits") ?? defaultRedditSubreddits;

  Future<void> setRedditSubreddits(List<String> subreddits) async {
    await _sharedPreferences.setStringList("reddit_subreddits", subreddits);
    notifyListeners();
  }

  String get redditSort => _sharedPreferences.getString("reddit_sort") ?? RedditSort.hot.key;

  Future<void> setRedditSort(String sort) async {
    await _sharedPreferences.setString("reddit_sort", sort);
    notifyListeners();
  }

  String get redditClientId => _sharedPreferences.getString("reddit_client_id") ?? "";

  Future<void> setRedditClientId(String clientId) async {
    await _sharedPreferences.setString("reddit_client_id", clientId.trim());
    notifyListeners();
  }

  String get redditClientSecret => _sharedPreferences.getString("reddit_client_secret") ?? "";

  Future<void> setRedditClientSecret(String secret) async {
    await _sharedPreferences.setString("reddit_client_secret", secret.trim());
    notifyListeners();
  }

  String? get redditCurrentTitle => _sharedPreferences.getString("reddit_current_title");
  String? get redditCurrentAuthor => _sharedPreferences.getString("reddit_current_author");
  String? get redditCurrentSubreddit => _sharedPreferences.getString("reddit_current_subreddit");

  Future<void> setRedditWallpaperInfo({
    required String title,
    required String author,
    required String subreddit,
  }) async {
    await _sharedPreferences.setString("reddit_current_title", title);
    await _sharedPreferences.setString("reddit_current_author", author);
    await _sharedPreferences.setString("reddit_current_subreddit", subreddit);
    notifyListeners();
  }
}
