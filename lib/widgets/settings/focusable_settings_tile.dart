import 'package:flutter/material.dart';
import 'package:flauncher/widgets/settings/fanatika_panel_style.dart';

class FocusableSettingsTile extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool autofocus;
  final String? focusId;
  final FocusOnKeyEventCallback? onKeyEvent;

  const FocusableSettingsTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onPressed,
    this.autofocus = false,
    this.focusId,
    this.onKeyEvent,
  }) : super(key: key);

  @override
  State<FocusableSettingsTile> createState() => _FocusableSettingsTileState();
}

class _FocusableSettingsTileState extends State<FocusableSettingsTile> {
  static final Map<String, String> _routeFocus = {};
  final FocusNode _focusNode = FocusNode(debugLabel: 'FanatikaSettingsTile');
  bool _focused = false;
  bool _didRestore = false;

  String get _identity {
    if (widget.focusId != null) return widget.focusId!;
    final title = widget.title;
    return title is Text ? (title.data ?? title.toStringShort()) : widget.key?.toString() ?? widget.runtimeType.toString();
  }
  String? _routeKey(BuildContext context) {
    final settings = ModalRoute.of(context)?.settings;
    if (settings?.name == null) return null;
    final arguments = settings!.arguments;
    final section = arguments is List ? arguments.join('|') : (arguments?.toString() ?? '');
    return '${settings.name}::$section';
  }

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestore) return;
    _didRestore = true;
    final name = _routeKey(context);
    if (name == null) return;
    if (_routeFocus[name] == _identity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.canRequestFocus) _focusNode.requestFocus();
      });
    }
  }
  @override void dispose() { _focusNode.dispose(); super.dispose(); }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: RepaintBoundary(
        child: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call()),
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => widget.onPressed?.call()),
          },
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: widget.onKeyEvent,
            autofocus: widget.autofocus && (_routeKey(context) == null ||
              !_routeFocus.containsKey(_routeKey(context))),
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                final name = _routeKey(context);
                if (name != null) {
                  // Bound retention; no navigation history, credentials or app data stored.
                  if (_routeFocus.length > 60) _routeFocus.clear();
                  _routeFocus[name] = _identity;
                }
              }
              if (hasFocus) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Scrollable.ensureVisible(context,
                    alignment: 0.12,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic);
                });
              }
              if (mounted && hasFocus != _focused) setState(() => _focused = hasFocus);
            },
            child: InkWell(
              canRequestFocus: false,
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(19),
              focusColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _focused ? FanatikaPanelStyle.focusedTile : FanatikaPanelStyle.tile,
                  borderRadius: BorderRadius.circular(19),
                  border: _focused
                      ? Border.all(color: const Color(0xFF94DAFF), width: 2)
                      : Border.all(color: Colors.transparent, width: 1),
                ),
                child: Row(
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: widget.subtitle != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                widget.title,
                                const SizedBox(height: 2),
                                widget.subtitle!,
                              ],
                            )
                          : widget.title,
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 16),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
