// Remote-focused Fanatika destination picker. The original Arc Favorites
// dialogs and the AppsService storage/reordering logic are not modified.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/fanatika_tv_action_row.dart';

import '../models/app.dart';
import '../models/category.dart';

class FanatikaAddToCategoryDialog extends StatefulWidget {
  final App selectedApplication;
  const FanatikaAddToCategoryDialog(this.selectedApplication, {super.key});

  @override State<FanatikaAddToCategoryDialog> createState() => _FanatikaAddToCategoryDialogState();
}

class _FanatikaAddToCategoryDialogState extends State<FanatikaAddToCategoryDialog> {
  final Map<int, FocusNode> _nodes = {};
  bool _requestedInitialFocus = false;

  FocusNode _node(int id) => _nodes.putIfAbsent(id,
    () => FocusNode(debugLabel: 'Destination $id'));

  @override void dispose() {
    for (final node in _nodes.values) { node.dispose(); }
    super.dispose();
  }

  @override Widget build(BuildContext context) => Selector<AppsService, List<Category>>(
    selector: (_, appsService) => appsService.categories
      .where((category) => !category.applications.any(
        (application) => application.packageName == widget.selectedApplication.packageName))
      .toList(),
    builder: (context, categories, _) {
      final localizations = AppLocalizations.of(context)!;
      if (categories.isNotEmpty && !_requestedInitialFocus) {
        _requestedInitialFocus = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _node(categories.first.id).requestFocus();
        });
      }
      return SidePanelDialog(
        width: 380,
        isRightSide: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(localizations.withEllipsisAddTo,
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const Text('Up / Down selects a destination. Press OK to add the app.',
            style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 12),
          Expanded(child: categories.isEmpty
            ? const Center(child: Text('Already added to all available sections.'))
            : ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return FanatikaTvActionRow(
                    key: ValueKey('destination_${category.id}_${category.name}'),
                    focusNode: _node(category.id),
                    autofocus: index == 0,
                    icon: Icons.add_circle_outline,
                    title: category.name,
                    subtitle: 'Press OK to add to this section',
                    moveUp: () => _node(categories[(index - 1).clamp(0, categories.length - 1).toInt()].id).requestFocus(),
                    moveDown: () => _node(categories[(index + 1).clamp(0, categories.length - 1).toInt()].id).requestFocus(),
                    onPressed: () async {
                      await context.read<AppsService>().addToCategory(widget.selectedApplication, category);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  );
                },
              )),
        ]),
      );
    },
  );
}
