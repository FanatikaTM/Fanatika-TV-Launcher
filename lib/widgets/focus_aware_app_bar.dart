import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/fanatika_quick_settings_dialog.dart';
import 'package:flauncher/widgets/tv_top_navigation_dialog.dart';
import 'package:flauncher/widgets/settings/tv_inputs_panel_page.dart';
import 'package:flauncher/widgets/settings/fanatika_v2_page.dart';
import 'package:flauncher/widgets/settings/fanatika_tools_hub.dart';
import 'package:flauncher/widgets/settings/fanatika_sleep_page.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/launcher_state.dart';
import '../providers/network_service.dart';
import '../providers/settings_service.dart';
import 'app_bar_focus_ring.dart';
import 'daily_wifi_usage_widget.dart';
import 'date_time_widget.dart';
import 'network_widget.dart';

class FocusAwareAppBar extends StatefulWidget implements PreferredSizeWidget
{
  final VoidCallback? onHomeRequested;
  const FocusAwareAppBar({Key? key, this.onHomeRequested}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FocusAwareAppBarState();
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class FocusAwareAppBarState extends State<FocusAwareAppBar>
{
  bool focused = false;
  late FocusNode _settingsFocusNode;

  @override
  void initState() {
    super.initState();
    _settingsFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _settingsFocusNode.dispose();
    super.dispose();
  }

  void focusSettings() {
    _settingsFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<SettingsService, LauncherState, ({bool autoHide, bool hideInGrid, bool appGridFocused})>(
      selector: (_, settings, launcherState) => (
        autoHide: settings.autoHideAppBarEnabled,
        hideInGrid: settings.hideStatusBarInGrid,
        appGridFocused: launcherState.appGridFocused,
      ),
      builder: (context, data, widget) {
        final isVisible = focused || (!data.autoHide && !(data.hideInGrid && data.appGridFocused));

        return Focus(
          canRequestFocus: false,
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              context.read<LauncherState>().setAppGridFocused(false);
            }
            setState(() {
              focused = hasFocus;
            });
          },
          child: IgnorePointer(
            ignoring: !isVisible,
            child: AnimatedOpacity(
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 200),
              opacity: isVisible ? 1.0 : 0.0,
              child: ClipRect(
                child: AnimatedContainer(
                  curve: Curves.decelerate,
                  duration: const Duration(milliseconds: 200),
                  height: isVisible ? kToolbarHeight : 0,
                  child: OverflowBox(
                    minHeight: 0,
                    maxHeight: kToolbarHeight,
                    alignment: Alignment.topCenter,
                    child: widget!,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: RepaintBoundary(
        child: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: context.watch<SettingsService>().fanatikaStatusBarStyle == 'Solid'
            ? const Color(0xFF11283A)
            : context.watch<SettingsService>().fanatikaStatusBarStyle == 'Glass'
              ? const Color(0xBB13243D)
              : context.watch<SettingsService>().fanatikaStatusBarStyle == 'Compact'
                ? const Color(0x99141C2B) : Colors.transparent,
          shape: context.watch<SettingsService>().fanatikaStatusBarStyle == 'Glass'
            ? const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)))
            : null,
          // Left side: Settings, Network indicator, WiFi usage
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TV-friendly Quick Settings inspired by the MiTV-M0EU0 panel.
              AppBarFocusRing(
                onPressed: () => showDialog<void>(
                  context: context, builder: (_) => const FanatikaQuickSettingsDialog()),
                semanticLabel: 'Quick Settings',
                child: const Icon(Icons.dashboard_customize_outlined, size: 21, color: Colors.white),
              ),
              const SizedBox(width: 8),
              // Google TV-inspired pill navigation. These are Fanatika routes,
              // not a replacement for the TV's protected OEM HOME handler.
              ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xE1394A61),
                    borderRadius: BorderRadius.circular(32)),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    AppBarFocusRing(
                      onPressed: () => showDialog<void>(context: context,
                        builder: (_) => TvTopNavigationDialog(
                          tab: TvTopTab.home, onGoHome: widget.onHomeRequested)),
                      semanticLabel: 'Home menu',
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE8F1F9),
                          borderRadius: BorderRadius.circular(18)),
                        child: const Text('Home', style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: Color(0xFF253D5C))),
                      )),
                    AppBarFocusRing(
                      onPressed: () => showDialog<void>(context: context,
                        builder: (_) => const TvTopNavigationDialog(tab: TvTopTab.apps)),
                      semanticLabel: 'Apps menu',
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: const Text('Apps', style: TextStyle(fontSize: 13, color: Colors.white))),
                    AppBarFocusRing(
                      onPressed: () => showDialog<void>(context: context,
                        builder: (_) => const TvTopNavigationDialog(tab: TvTopTab.tools)),
                      semanticLabel: 'Tools menu',
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: const Text('Tools', style: TextStyle(fontSize: 13, color: Colors.white))),
                  ])),
                const SizedBox(width: 10),
              ],
              // Settings button
              AppBarFocusRing(
                focusNode: _settingsFocusNode,
                onPressed: () => showDialog(context: context, builder: (_) => const SettingsPanel()),
                semanticLabel: 'Settings',
                child: const Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppBarFocusRing(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const SettingsPanel(initialRoute: TvInputsPanelPage.routeName),
                ),
                semanticLabel: 'TV Sources / Inputs',
                child: const Icon(Icons.settings_input_hdmi, size: 20, color: Colors.white),
              ),
              if (context.watch<SettingsService>().fanatikaStatusApps) ...[
                const SizedBox(width: 8),
                AppBarFocusRing(
                  onPressed: () => showDialog(context: context, builder: (_) => const SettingsPanel(initialRoute: ApplicationsPanelPage.routeName)),
                  semanticLabel: 'Applications', child: const Icon(Icons.apps, size: 20, color: Colors.white)),
              ],
              if (context.watch<SettingsService>().fanatikaStatusTools) ...[
                const SizedBox(width: 8),
                AppBarFocusRing(
                  onPressed: () => showDialog(context: context, builder: (_) => const SettingsPanel(initialRoute: FanatikaToolsHub.routeName)),
                  semanticLabel: 'Tools', child: const Icon(Icons.tune, size: 20, color: Colors.white)),
              ],
              if (context.watch<SettingsService>().fanatikaStatusSleep) ...[
                const SizedBox(width: 8),
                AppBarFocusRing(
                  onPressed: () => showDialog(context: context, builder: (_) => const SettingsPanel(initialRoute: FanatikaSleepPage.routeName)),
                  semanticLabel: 'Sleep and standby settings', child: const Icon(Icons.bedtime_outlined, size: 20, color: Colors.white)),
              ],
              if (context.watch<SettingsService>().fanatikaStatusWeather) ...[
                const SizedBox(width: 8),
                AppBarFocusRing(
                  onPressed: () => showDialog(context: context, builder: (_) => const SettingsPanel(initialRoute: FanatikaV2Page.routeName)),
                  semanticLabel: 'Weather options', child: const Icon(Icons.cloud_outlined, size: 20, color: Colors.white)),
              ],
              const SizedBox(width: 8),
              // Network indicator (conditionally shown)
              Selector<SettingsService, bool>(
                selector: (_, settings) => settings.showNetworkIndicatorInStatusBar,
                builder: (context, showNetwork, _) => showNetwork
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppBarFocusRing(
                        onPressed: () => context.read<NetworkService>().openWifiSettings(),
                        semanticLabel: 'Network',
                        child: const NetworkWidget(),
                      ),
                    )
                  : const SizedBox.shrink(),
              ),
              // WiFi usage widget
              Selector<SettingsService, bool>(
                selector: (_, settings) => settings.showWifiWidgetInStatusBar,
                builder: (context, showWifi, _) => showWifi
                  ? const DailyWifiUsageWidget()
                  : const SizedBox.shrink(),
              ),
              ],
            ),
          ),
          // Right side: Date/Time only
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 32),
              child: Selector<SettingsService,
                  ({
                    bool showDateInStatusBar,
                    bool showTimeInStatusBar,
                    String dateFormat,
                    String timeFormat })>(
                selector: (context, service) => (
                showDateInStatusBar: service.showDateInStatusBar,
                showTimeInStatusBar: service.showTimeInStatusBar,
                dateFormat: service.dateFormat,
                timeFormat: service.timeFormat),
                builder: (context, dateTimeSettings, _) {
                  // Define standard text style
                  final textStyle = TextStyle(
                    fontSize: context.watch<SettingsService>().fanatikaStatusBarStyle == 'Compact'
                      ? 16 : 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)
                    ],
                  );

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date
                      if (dateTimeSettings.showDateInStatusBar)
                        DateTimeWidget(
                          dateTimeSettings.dateFormat,
                          key: const Key("statusbar_date"),
                          updateInterval: const Duration(minutes: 1),
                          textStyle: textStyle,
                        ),
                      
                      if (dateTimeSettings.showDateInStatusBar && dateTimeSettings.showTimeInStatusBar)
                          const SizedBox(width: 16),

                      // Clock
                      if (dateTimeSettings.showTimeInStatusBar)
                        DateTimeWidget(
                          dateTimeSettings.timeFormat,
                          key: const Key("statusbar_clock"),
                          updateInterval: const Duration(minutes: 1),
                          textStyle: textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                    ]
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

