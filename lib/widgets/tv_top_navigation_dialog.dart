// TV remote-friendly Home / Apps / Tools menus. Reuses existing settings pages.
// The original Arc Favorites storage, HOME role, and Xiaomi system UI are untouched.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/appearance_panel_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/misc_panel_page.dart';
import 'package:flauncher/widgets/settings/fanatika_tools_hub.dart';
import 'package:flauncher/widgets/settings/fanatika_updates_page.dart';
import 'package:flauncher/widgets/settings/fanatika_usb_page.dart';
import 'package:flauncher/widgets/settings/fanatika_sleep_page.dart';
import 'package:flauncher/widgets/settings/tv_inputs_panel_page.dart';
import 'package:flauncher/widgets/fanatika_quick_settings_dialog.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

enum TvTopTab { home, apps, tools }

class TvTopNavigationDialog extends StatelessWidget {
  final TvTopTab tab;
  final VoidCallback? onGoHome;
  const TvTopNavigationDialog({super.key, required this.tab, this.onGoHome});

  Future<void> _settings(BuildContext context, String route) async {
    await showDialog<void>(context: context,
      builder: (_) => SettingsPanel(initialRoute: route));
  }

  Widget _action(BuildContext context, IconData icon, String title,
      VoidCallback onPressed, {String? note, bool autofocus = false}) =>
    FocusableSettingsTile(
      autofocus: autofocus,
      leading: Icon(icon, color: const Color(0xFFC9DBED)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: note == null ? null : Text(note,
        style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white60),
      onPressed: onPressed);

  Widget _toggle(BuildContext context, String title, bool enabled,
      Future<void> Function(bool) update, {bool autofocus = false}) =>
    _action(context, enabled ? Icons.toggle_on : Icons.toggle_off, title,
      () async { await update(!enabled); },
      autofocus: autofocus, note: enabled ? 'On' : 'Off');

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final label = switch (tab) {
      TvTopTab.home => 'Home',
      TvTopTab.apps => 'Apps',
      TvTopTab.tools => 'Tools',
    };
    final entries = <Widget>[
      if (tab == TvTopTab.home) ...[
        _action(context, Icons.home_outlined, 'Go to Home', () {
          Navigator.of(context).pop();
          onGoHome?.call();
        }, note: 'Return to the top of the launcher', autofocus: true),
        _toggle(context, 'Watch Next', settings.showWatchNextSection,
          settings.setShowWatchNextSection),
        _toggle(context, 'Weather', settings.showFanatikaWeather,
          settings.setShowFanatikaWeather),
        _toggle(context, 'Large selected-app title', settings.showFanatikaHero,
          settings.setShowFanatikaHero),
        _action(context, Icons.wallpaper_outlined, 'Wallpapers and backgrounds',
          () => _settings(context, WallpaperPanelPage.routeName)),
        _action(context, Icons.tune, 'Home appearance',
          () => _settings(context, AppearancePanelPage.routeName)),
        _action(context, Icons.view_quilt_outlined, 'Status bar',
          () => _settings(context, StatusBarPanelPage.routeName)),
        _action(context, Icons.dashboard_customize_outlined, 'Quick Settings',
          () => showDialog<void>(context: context,
            builder: (_) => const FanatikaQuickSettingsDialog())),
      ],
      if (tab == TvTopTab.apps) ...[
        _action(context, Icons.apps, 'Installed applications',
          () => _settings(context, ApplicationsPanelPage.routeName), autofocus: true),
        _action(context, Icons.favorite_border, 'Favorites and sections',
          () => _settings(context, LauncherSectionsPanelPage.routeName),
          note: 'Add, remove and reorder apps in the original Arc interface'),
        _action(context, Icons.grid_view_outlined, 'App grid and section layout',
          () => _settings(context, InterfaceSettingsPage.routeName)),
        _toggle(context, 'Show app names below icons',
          settings.showAppNamesBelowIcons, settings.setShowAppNamesBelowIcons),
        _action(context, Icons.burst_mode_outlined, 'Focus and selected-app style',
          () => _settings(context, AppearancePanelPage.routeName)),
        _action(context, Icons.tune, 'Additional app and section options',
          () => _settings(context, MiscPanelPage.routeName)),
      ],
      if (tab == TvTopTab.tools) ...[
        _action(context, Icons.settings_outlined, 'All Settings',
          () => _settings(context, SettingsPanelPage.routeName), autofocus: true),
        _action(context, Icons.tune, 'Customization tools',
          () => _settings(context, FanatikaToolsHub.routeName)),
        _action(context, Icons.system_update, 'Updates',
          () => _settings(context, FanatikaUpdatesPage.routeName)),
        _action(context, Icons.usb, 'USB storage',
          () => _settings(context, FanatikaUsbPage.routeName)),
        _action(context, Icons.bedtime_outlined, 'Sleep and standby',
          () => _settings(context, FanatikaSleepPage.routeName)),
        _action(context, Icons.settings_input_hdmi, 'TV inputs and HDMI',
          () => _settings(context, TvInputsPanelPage.routeName)),
        _action(context, Icons.dashboard_customize, 'Quick Settings',
          () => showDialog<void>(context: context,
            builder: (_) => const FanatikaQuickSettingsDialog())),
        _action(context, Icons.settings_applications, 'Android TV settings',
          () async => context.read<AppsService>().openSettings()),
      ],
    ];
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: const Color(0xFF263A51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFF59718A))),
      child: SizedBox(
        width: (screen.width * .52).clamp(350.0, 620.0),
        height: (screen.height * .75).clamp(320.0, 630.0),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
            child: Row(children: [
              Expanded(child: Text(label,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
              IconButton(tooltip: 'Close menu', onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
            ])),
          const Divider(height: 1, color: Colors.white24),
          Expanded(child: ListView(children: entries)),
        ]),
      ),
    );
  }
}
