/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/fanatika_add_to_category_dialog.dart';
import 'package:flauncher/widgets/fanatika_tv_action_row.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/tv_media_picker.dart';

import '../models/app.dart';
import '../models/category.dart';

class ApplicationInfoPanel extends StatefulWidget {
  final Category? category;
  final App application;
  final ImageProvider? applicationIcon;

  const ApplicationInfoPanel({
    super.key,
    required this.category,
    required this.application,
    this.applicationIcon,
  });

  @override
  State<ApplicationInfoPanel> createState() => _ApplicationInfoPanelState();
}

class _ApplicationInfoPanelState extends State<ApplicationInfoPanel> {
  late Future<bool> _hasCustomBannerFuture;
  final Map<String, FocusNode> _actionNodes = {};
  List<String> _visibleActions = const [];
  bool _initialFocusRequested = false;
  late String _selectedActionId;

  FocusNode _node(String id) => _actionNodes.putIfAbsent(id,
    () => FocusNode(debugLabel: 'App action $id'));

  void _moveAction(String id, int delta) {
    final index = _visibleActions.indexOf(id);
    if (index < 0) return;
    final next = (index + delta).clamp(0, _visibleActions.length - 1).toInt();
    final target = _visibleActions[next];
    setState(() => _selectedActionId = target);
    _node(target).requestFocus();
  }

  @override void dispose() {
    for (final node in _actionNodes.values) { node.dispose(); }
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _selectedActionId = 'open_${widget.application.packageName}';
    _hasCustomBannerFuture = context.read<AppsService>()
        .hasCustomBanner(widget.application.packageName);
  }

  Future<void> _showSnack(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setCustomBanner() async {
    try {
      final media = await TvMediaPicker.show(context, mode: TvMediaPickerMode.image);
      if (media == null) return;
      final docDir = await getApplicationDocumentsDirectory();
      final safePackageName = widget.application.packageName
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final savedImage = File('${docDir.path}/custom_banner_$safePackageName.png');
      await File(media.path).copy(savedImage.path);
      await context.read<AppsService>().setCustomAppBanner(widget.application.packageName, savedImage.path);
      if (!mounted) return;
      setState(() {
        _hasCustomBannerFuture = context.read<AppsService>()
            .hasCustomBanner(widget.application.packageName);
      });
      Navigator.of(context).pop(ApplicationInfoPanelResult.none);
    } catch (e) {
      await _showSnack('Failed to set banner: $e');
    }
  }

  Future<void> _clearCustomBanner() async {
    try {
      await context.read<AppsService>().removeCustomAppBanner(widget.application.packageName);
      if (!mounted) return;
      setState(() {
        _hasCustomBannerFuture = context.read<AppsService>()
            .hasCustomBanner(widget.application.packageName);
      });
      Navigator.of(context).pop(ApplicationInfoPanelResult.none);
    } catch (e) {
      await _showSnack('Failed to clear banner: $e');
    }
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onPressed,
    bool autofocus = false,
    String? focusId,
  }) {
    final id = focusId ?? title;
    return FanatikaTvActionRow(
      key: ValueKey('app_action_$id'),
      focusNode: _node(id),
      autofocus: autofocus,
      selected: _selectedActionId == id,
      onFocusChanged: (focused) {
        if (focused && mounted && _selectedActionId != id) {
          setState(() => _selectedActionId = id);
        }
      },
      icon: icon,
      title: title,
      subtitle: subtitle,
      moveUp: () => _moveAction(id, -1),
      moveDown: () => _moveAction(id, 1),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return SidePanelDialog(
      width: 340,
      isRightSide: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: widget.applicationIcon != null
                    ? Image(image: widget.applicationIcon!, width: 50)
                    : const Icon(Icons.image_not_supported_outlined),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.application.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v${widget.application.version}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.application.packageName,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(),
          // Visible on TV: confirms the newly installed menu, not Android's
          // underlying application version shown above.
          const Text('Fanatika menu v2.9.14',
            style: TextStyle(fontSize: 11, color: Color(0xCCDBEAF6))),
          const SizedBox(height: 6),
          Expanded(
            child: FocusScope(
              autofocus: true,
              child: FutureBuilder<bool>(
              future: _hasCustomBannerFuture,
              builder: (context, snapshot) {
                final appsService = context.watch<AppsService>();
                final isInFavorites = appsService.isAppInFavorites(widget.application);
                final hasCustomBanner = snapshot.data ?? false;
                final pkg = widget.application.packageName;
                _visibleActions = [
                  'open_$pkg', 'fav_$pkg', 'hide_$pkg', 'category_$pkg',
                  if (widget.category?.sort == CategorySort.manual) 'reorder_$pkg',
                  if (widget.category != null) 'remove_$pkg',
                  'banner_set_$pkg',
                  if (hasCustomBanner) 'banner_clear_$pkg',
                  'info_$pkg', 'uninstall_$pkg',
                ];
                if (!_initialFocusRequested) {
                  _initialFocusRequested = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      FocusScope.of(context).requestFocus(_node('open_$pkg'));
                    }
                  });
                }
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _tile(
                      icon: Icons.open_in_new,
                      title: localizations.open,
                      subtitle: 'Launch this app now',
                      autofocus: true,
                      focusId: 'open_${widget.application.packageName}',
                      onPressed: () async {
                        await context.read<AppsService>().launchApp(widget.application);
                        if (context.mounted) {
                          Navigator.of(context).pop(ApplicationInfoPanelResult.none);
                        }
                      },
                    ),
                    _tile(
                      icon: isInFavorites ? Icons.star : Icons.star_border,
                      title: isInFavorites ? 'Remove from Fav' : 'Add to Fav',
                      subtitle: isInFavorites
                        ? 'Remove this app from Favorites'
                        : 'Add this app to Favorites',
                      focusId: 'fav_${widget.application.packageName}',
                      onPressed: () async {
                        await appsService.toggleFavorite(widget.application);
                        if (context.mounted) {
                          Navigator.of(context).pop(ApplicationInfoPanelResult.none);
                        }
                      },
                    ),
                    _tile(
                      icon: widget.application.hidden ? Icons.visibility : Icons.visibility_off_outlined,
                      title: widget.application.hidden ? localizations.show : localizations.hide,
                      subtitle: widget.application.hidden
                        ? 'Show this app again on the launcher'
                        : 'Hide this app from the launcher',
                      focusId: 'hide_${widget.application.packageName}',
                      onPressed: () async {
                        if (widget.application.hidden) {
                          await context.read<AppsService>().showApplication(widget.application);
                        } else {
                          await context.read<AppsService>().hideApplication(widget.application);
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop(ApplicationInfoPanelResult.none);
                        }
                      },
                    ),
                    _tile(
                      icon: Icons.add_box_outlined,
                      title: 'Add to Category',
                      subtitle: 'Choose another section for this app',
                      focusId: 'category_${widget.application.packageName}',
                      onPressed: () async {
                        await showDialog<void>(
                          context: context,
                          builder: (_) => FanatikaAddToCategoryDialog(widget.application),
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop(ApplicationInfoPanelResult.none);
                        }
                      },
                    ),
                    if (widget.category?.sort == CategorySort.manual)
                      _tile(
                        icon: Icons.open_with,
                        title: localizations.reorder,
                        subtitle: 'Move this app inside the current row',
                        focusId: 'reorder_${widget.application.packageName}',
                        onPressed: () => Navigator.of(context).pop(ApplicationInfoPanelResult.reorderApp),
                      ),
                    if (widget.category != null)
                      _tile(
                        icon: Icons.delete_sweep_outlined,
                        title: localizations.removeFrom(widget.category!.name),
                        subtitle: 'Remove this app from the current section',
                        focusId: 'remove_${widget.application.packageName}',
                        onPressed: () async {
                          await context.read<AppsService>().removeFromCategory(widget.application, widget.category!);
                          if (context.mounted) {
                            Navigator.of(context).pop(ApplicationInfoPanelResult.none);
                          }
                        },
                      ),
                    const Divider(height: 18),
                    _tile(
                      icon: Icons.image_search,
                      title: 'Set Custom Banner',
                      subtitle: 'Use your own banner image for this app',
                      focusId: 'banner_set_${widget.application.packageName}',
                      onPressed: _setCustomBanner,
                    ),
                    if (hasCustomBanner)
                      _tile(
                        icon: Icons.hide_image_outlined,
                        title: 'Clear Custom Banner',
                        subtitle: 'Restore the original app artwork',
                        focusId: 'banner_clear_${widget.application.packageName}',
                        onPressed: _clearCustomBanner,
                      ),
                    const Divider(height: 18),
                    _tile(
                      icon: Icons.info_outlined,
                      title: localizations.appInfo,
                      subtitle: 'Open Android app information',
                      focusId: 'info_${widget.application.packageName}',
                      onPressed: () => context.read<AppsService>().openAppInfo(widget.application),
                    ),
                    _tile(
                      icon: Icons.delete_outlined,
                      title: localizations.uninstall,
                      subtitle: 'Remove this app from the TV',
                      focusId: 'uninstall_${widget.application.packageName}',
                      onPressed: () async {
                        await context.read<AppsService>().uninstallApp(widget.application);
                        if (context.mounted) {
                          Navigator.of(context).pop(ApplicationInfoPanelResult.none);
                        }
                      },
                    ),
                  ],
                );
              },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum ApplicationInfoPanelResult { none, reorderApp }
