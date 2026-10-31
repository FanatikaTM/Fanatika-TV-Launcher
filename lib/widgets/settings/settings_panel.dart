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

import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/settings/fanatika_panel_style.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/gradient_panel_page.dart';
import 'package:flauncher/widgets/settings/reddit_subreddits_panel_page.dart';
import 'package:flauncher/widgets/settings/reddit_wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/unsplash_slideshow_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flauncher/widgets/settings/tv_inputs_panel_page.dart';
import 'package:flauncher/widgets/settings/fanatika_v2_page.dart';
import 'package:flauncher/widgets/settings/plex_continue_watching_page.dart';
import 'package:flauncher/widgets/settings/fanatika_tools_hub.dart';
import 'package:flauncher/widgets/settings/fanatika_updates_page.dart';
import 'package:flauncher/widgets/settings/fanatika_usb_page.dart';
import 'package:flauncher/widgets/settings/fanatika_sleep_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/fanatika_top_bar_editor_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/wifi_usage_period_page.dart';
import 'package:flauncher/widgets/settings/back_button_action_page.dart';
import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/app_details_page.dart';
import 'package:flauncher/widgets/settings/accent_color_page.dart';
import 'package:flauncher/widgets/settings/brightness_settings_page.dart';
import 'package:flauncher/widgets/settings/appearance_panel_page.dart';
import 'package:flauncher/widgets/settings/focus_border_thickness_page.dart';
import 'package:flauncher/widgets/settings/misc_panel_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flauncher/widgets/settings/unified_settings_pages.dart';
import 'package:flauncher/widgets/settings/fanatika_title_font_page.dart';
import 'package:flauncher/widgets/settings/screensaver_clock_style_page.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/widgets/settings/slideshow_sources_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SettingsPanel extends StatefulWidget {
  final String? initialRoute;

  const SettingsPanel({Key? key, this.initialRoute}) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final TextEditingController _pinController = TextEditingController();
  bool _pinUnlocked = false;
  String _pinNotice = '';

  @override void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _unlockWithPin(String storedPin) {
    final parts = storedPin.split(':');
    final digest = parts.length == 2
      ? sha256.convert(utf8.encode('${parts[0]}:${_pinController.text}')).toString()
      : '';
    if (parts.length == 2 && digest == parts[1]) {
      setState(() { _pinUnlocked = true; _pinNotice = ''; });
      _pinController.clear();
    } else {
      setState(() => _pinNotice = 'Incorrect PIN');
    }
  }

  Widget _pinGate(BuildContext context, String storedPin) => SidePanelDialog(
    width: FanatikaPanelStyle.panelWidth(MediaQuery.sizeOf(context)), isRightSide: true,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FanatikaPanelHeader(title: 'Settings locked'),
      const Padding(padding: EdgeInsets.symmetric(vertical: 14),
        child: Text('Enter your existing Fanatika settings PIN to open the merged settings.')),
      TextField(controller: _pinController, obscureText: true,
        autofocus: true, keyboardType: TextInputType.number,
        onSubmitted: (_) => _unlockWithPin(storedPin),
        decoration: const InputDecoration(labelText: 'Settings PIN')),
      if (_pinNotice.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(_pinNotice)),
      const SizedBox(height: 10),
      FilledButton(onPressed: () => _unlockWithPin(storedPin), child: const Text('Unlock')),
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
    ]));

  @override
  Widget build(BuildContext context) {
    final storedPin = context.watch<SettingsService>().fanatikaSettingsPin;
    if (storedPin.isNotEmpty && !_pinUnlocked) {
      return Material(color: Colors.black54, child: _pinGate(context, storedPin));
    }
    return Theme(
      data: Theme.of(context).copyWith(
        dialogTheme: DialogThemeData(
          backgroundColor: FanatikaPanelStyle.base,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.white24)),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 21,
            fontWeight: FontWeight.w700),
          contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ),
      child: WillPopScope(
      onWillPop: () async => !await _navigatorKey.currentState!.maybePop(),
      child: Scaffold(
        backgroundColor: Colors.black54, // Dim the background
        body: Stack(
          children: [
            // Tap outside to close
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
            // The side panel
            SidePanelDialog(
              width: FanatikaPanelStyle.panelWidth(MediaQuery.sizeOf(context)),
              isRightSide: true,
              child: Navigator(
                key: _navigatorKey,
                initialRoute: widget.initialRoute ?? SettingsPanelPage.routeName,
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case UnifiedHomePage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const UnifiedHomePage());
                    case UnifiedAppsPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const UnifiedAppsPage());
                    case UnifiedMediaPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const UnifiedMediaPage());
                    case UnifiedWallpaperPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const UnifiedWallpaperPage());
                    case UnifiedSystemPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const UnifiedSystemPage());
                    case UnifiedAdvancedPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const UnifiedAdvancedPage());
                    case FanatikaTitleFontPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const FanatikaTitleFontPage());
                    case FanatikaToolsHub.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const UnifiedSystemPage());
                    case FanatikaUpdatesPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const FanatikaUpdatesPage());
                    case FanatikaUsbPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const FanatikaUsbPage());
                    case PlexContinueWatchingPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const PlexContinueWatchingPage());
                    case FanatikaV2Page.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => FanatikaV2Page(
                        sections: (settings.arguments as List<String>?) ?? const [],
                        unlockedByParent: storedPin.isEmpty || _pinUnlocked));
                    case FanatikaSleepPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const FanatikaSleepPage());
                    case TvInputsPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const TvInputsPanelPage());
                    case SettingsPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => SettingsPanelPage());
                    case GeneralSettingsPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => GeneralSettingsPage());
                    case InterfaceSettingsPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => InterfaceSettingsPage());
                    case WallpaperPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => WallpaperPanelPage());
                    case FanatikaTopBarEditorPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const FanatikaTopBarEditorPage());
                    case StatusBarPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => StatusBarPanelPage());
                    case GradientPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => GradientPanelPage());
                    case SlideshowSourcesPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => SlideshowSourcesPanelPage());
                    case UnsplashSlideshowPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => UnsplashSlideshowPanelPage());
                    case RedditWallpaperPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const RedditWallpaperPanelPage());
                    case RedditSubredditsPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const RedditSubredditsPanelPage());
                    case ApplicationsPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => ApplicationsPanelPage());
                    case LauncherSectionsPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => LauncherSectionsPanelPage());
                    case LauncherSectionPanelPage.routeName:
                      return _FastPageRoute(
                        builder: (_) => LauncherSectionPanelPage(sectionIndex: settings.arguments as int?),
                      );
                    case WifiUsagePeriodPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => WifiUsagePeriodPage());
                    case BackButtonActionPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => BackButtonActionPage());
                    case DateTimeFormatPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => DateTimeFormatPage());
                    case AppearancePanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const AppearancePanelPage());
                    case FocusBorderThicknessPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const FocusBorderThicknessPage());
                    case MiscPanelPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => MiscPanelPage());
                    case ScreensaverClockStylePage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => const ScreensaverClockStylePage());
                    case AccentColorPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => AccentColorPage());
                    case BrightnessSettingsPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => BrightnessSettingsPage());
                    case AppDetailsPage.routeName:
                      return _FastPageRoute(settings: settings, builder: (_) => AppDetailsPage(application: settings.arguments as App));
                    default:
                      throw ArgumentError.value(settings.name, "settings.name", "Route not supported.");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

/// A faster page route with a 150ms slide transition instead of
/// the default 300ms Material transition.
class _FastPageRoute<T> extends MaterialPageRoute<T> {
  _FastPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);
}
