import 'package:flauncher/widgets/fanatika_top_bar_tabs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/launcher_state.dart';
import '../providers/settings_service.dart';
import 'daily_wifi_usage_widget.dart';
import 'date_time_widget.dart';

class FocusAwareAppBar extends StatefulWidget implements PreferredSizeWidget
{
  final VoidCallback? onHomeRequested;
  final VoidCallback? onNavigateDown;
  const FocusAwareAppBar({Key? key, this.onHomeRequested, this.onNavigateDown}) : super(key: key);

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
  late FocusNode _homeFocusNode;

  @override
  void initState() {
    super.initState();
    _settingsFocusNode = FocusNode();
    _homeFocusNode = FocusNode(debugLabel: "Fanatika Home tab");
  }

  @override
  void dispose() {
    _settingsFocusNode.dispose();
    _homeFocusNode.dispose();
    super.dispose();
  }

  void focusHome() {
    _homeFocusNode.requestFocus();
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
              // Every actionable shortcut now lives inside the ONE text-only pill.
              FanatikaTopBarTabs(settingsFocusNode: _settingsFocusNode, homeFocusNode: _homeFocusNode,
                onGoHome: widget.onHomeRequested,
                onNavigateDown: widget.onNavigateDown),
              const SizedBox(width: 10),
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

