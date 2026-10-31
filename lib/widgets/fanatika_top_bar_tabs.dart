// Configurable, D-pad-friendly compact top navigation. Uses original
// Arc launcher FocusRing decoration and the existing pill background.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/app_bar_focus_ring.dart';
import 'package:flauncher/widgets/fanatika_quick_settings_dialog.dart';
import 'package:flauncher/widgets/fanatika_sleep_timer_dialog.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/unified_settings_pages.dart';
import 'package:flauncher/widgets/settings/fanatika_v2_page.dart';
import 'package:flauncher/widgets/settings/fanatika_updates_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';

class FanatikaTopBarTabs extends StatelessWidget {
  static bool _settingsDialogOpen = false;
  final FocusNode settingsFocusNode;
  final FocusNode homeFocusNode;
  final VoidCallback? onGoHome;
  final VoidCallback? onNavigateDown;
  const FanatikaTopBarTabs({super.key, required this.settingsFocusNode, required this.homeFocusNode, this.onGoHome, this.onNavigateDown});

  @override Widget build(BuildContext context) {
    final names = context.watch<SettingsService>().fanatikaTopBarTabs;
    return Container(
      decoration: BoxDecoration(color: const Color(0xE1394A61),
        borderRadius: BorderRadius.circular(32)),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final name in names)
          Focus(canRequestFocus: false,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown && onNavigateDown != null) {
                onNavigateDown!();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            }, child: AppBarFocusRing(
            focusNode: name == 'Settings' ? settingsFocusNode : (name == 'Home' ? homeFocusNode : null),
            onPressed: () => _open(context, name),
            semanticLabel: name,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: name == 'Home' ? const Color(0xFFE8F1F9) : Colors.transparent,
                borderRadius: BorderRadius.circular(18)),
              child: name == 'Quick' ? const Icon(Icons.grid_view_rounded,
                  size: 22, color: Colors.white) : Text(name, style: TextStyle(fontSize: 13,
                fontWeight: name == 'Home' ? FontWeight.w700 : FontWeight.w500,
                color: name == 'Home' ? const Color(0xFF253D5C) : Colors.white))),
          )),
      ]),
    );
  }

  Future<void> _openInput() async {
    try { await FLauncherChannel().openTvSourcePicker(); } catch (_) {
      // OEM picker errors are explained in TV & tools > Input instead.
    }
  }

  void _open(BuildContext context, String name) {
    Future<void> settings([String? route]) async {
      if (_settingsDialogOpen) return;
      _settingsDialogOpen = true;
      try {
        await showDialog<void>(context: context,
          builder: (_) => SettingsPanel(initialRoute: route));
      } finally {
        _settingsDialogOpen = false;
      }
    }
    switch (name) {
      case 'Home':
        if (onGoHome != null) { onGoHome!(); } else { homeFocusNode.requestFocus(); }
        return;
      case 'Apps': settings(UnifiedAppsPage.routeName); return;
      case 'Settings': settings(); return;
      case 'Weather': settings(UnifiedMediaPage.routeName); return;
      case 'Sleep': showDialog<void>(context: context,
          builder: (_) => const FanatikaSleepTimerDialog()); return;
      case 'Quick': showDialog<void>(context: context,
          builder: (_) => const FanatikaQuickSettingsDialog()); return;
      case 'Updates': settings(FanatikaUpdatesPage.routeName); return;
      case 'Bar': settings(StatusBarPanelPage.routeName); return;
      case 'Network': context.read<NetworkService>().openWifiSettings(); return;
      case 'Input':
        _openInput(); // Only manufacturer's picker; no custom inputs dialog.
        return;
    }
  }
}
