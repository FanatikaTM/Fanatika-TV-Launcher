// Fanatika additions to Arc Launcher (GPL-3.0-or-later).
// SAF export/import stores preferences and the original Favorites order.
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/flauncher_channel.dart';

class FanatikaBackupService {
  static const MethodChannel _files = MethodChannel('me.efesser.flauncher/method');

  static Map<String, dynamic> snapshot(SettingsService settings, AppsService apps) {
    final favorites = apps.categories.where((category) => category.name == 'Favorites').toList();
    return {
      'format': 'fanatika-launcher-backup',
      'schema': 1,
      'created': DateTime.now().toUtc().toIso8601String(),
      'preferences': settings.fanatikaExportPreferences(),
      'favorites': favorites.isEmpty
          ? <String>[]
          : favorites.first.applications.map((app) => app.packageName).toList(),
    };
  }

  static Future<bool> export(SettingsService settings, AppsService apps) async {
    return await _files.invokeMethod<bool>(
      'fanatikaSaveBackup', const JsonEncoder.withIndent('  ').convert(snapshot(settings, apps)),
    ) ?? false;
  }

  static Future<Map<String, dynamic>?> selectImport() async {
    final contents = await _files.invokeMethod<String>('fanatikaReadBackup');
    if (contents == null) return null;
    final raw = jsonDecode(contents);
    if (raw is! Map || raw['format'] != 'fanatika-launcher-backup' || raw['schema'] != 1) {
      throw const FormatException('Not a compatible Fanatika backup');
    }
    if (raw['preferences'] is! Map || raw['favorites'] is! List) {
      throw const FormatException('Incomplete backup');
    }
    if ((raw['favorites'] as List).length > 300) {
      throw const FormatException('Too many favorite apps');
    }
    final fav = (raw['favorites'] as List).map((e) => e.toString()).toList();
    if (fav.any((item) => item.length > 200)) throw const FormatException('Invalid package ID');
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> restore(
    Map<String, dynamic> data, SettingsService settings, AppsService apps,
  ) async {
    // UI obtains explicit approval before calling; inaccessible apps are skipped.
    final names = (data['favorites'] as List).map((e) => e.toString()).toList();
    final available = {for (final app in apps.applications) app.packageName: app};
    final originals = apps.categories.where((category) => category.name == 'Favorites').toList();
    if (originals.isNotEmpty) {
      for (final app in originals.first.applications.toList()) {
        await apps.removeFromFavorites(app);
      }
    }
    for (final name in names.toSet()) {
      final app = available[name];
      if (app != null) await apps.addToFavorites(app);
    }
    await settings.fanatikaImportPreferences(Map<String, dynamic>.from(data['preferences'] as Map));
    // Restore only the non-privileged key preference. Android device-admin and
    // Accessibility approval are intentionally NEVER granted via backup.
    final prefs = Map<String, dynamic>.from(data['preferences'] as Map);
    final shortcut = prefs['fanatika_v2_sleep_shortcut_key'];
    if (shortcut is int && const [0, 82, 165, 172, 183, 184, 185, 186].contains(shortcut)) {
      await FLauncherChannel().fanatikaSetSleepShortcut(shortcut);
    }
  }

  static Future<String?> selectReviewedUpdate() => _files.invokeMethod<String>('fanatikaPickUpdateApk');
}
