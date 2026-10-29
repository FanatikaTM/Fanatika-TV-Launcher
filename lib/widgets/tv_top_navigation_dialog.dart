// Single routing layer for the existing top navigation buttons.
// The app bar itself is unchanged; no second menu UI is created here.
import 'package:flutter/material.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/unified_settings_pages.dart';

enum TvTopTab { home, apps, tools }

class TvTopNavigationDialog extends StatelessWidget {
  final TvTopTab tab;
  final VoidCallback? onGoHome;
  const TvTopNavigationDialog({super.key, required this.tab, this.onGoHome});
  @override Widget build(BuildContext context) {
    final route = switch (tab) {
      TvTopTab.home => UnifiedHomePage.routeName,
      TvTopTab.apps => UnifiedAppsPage.routeName,
      TvTopTab.tools => UnifiedSystemPage.routeName,
    };
    return SettingsPanel(initialRoute: route);
  }
}
