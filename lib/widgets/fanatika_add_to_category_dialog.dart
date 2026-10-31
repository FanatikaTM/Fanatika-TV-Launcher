import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../models/app.dart';
import '../models/category.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

class FanatikaAddToCategoryDialog extends StatelessWidget {
  final App selectedApplication;

  FanatikaAddToCategoryDialog(this.selectedApplication);

  @override
  Widget build(BuildContext context) => Selector<AppsService, List<Category>>(
        selector: (_, appsService) => appsService.categories
            .where((category) => !category.applications.any((application) => application.packageName == selectedApplication.packageName))
            .toList(),
        builder: (context, categories, _) {
          AppLocalizations localizations = AppLocalizations.of(context)!;

          return SidePanelDialog(
            width: 380,
            isRightSide: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.withEllipsisAddTo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                const Text('Choose a destination with Up / Down. The blue row is the focused option.',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return FocusableSettingsTile(
                        key: ValueKey('destination_${category.id}_${category.name}'),
                        focusId: 'destination_${category.id}_${category.name}',
                        autofocus: index == 0,
                        leading: const Icon(Icons.add_circle_outline),
                        title: Text(category.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Press OK to add to this section',
                          style: TextStyle(fontSize: 12, color: Colors.white70)),
                        trailing: const Icon(Icons.chevron_right),
                        onPressed: () async {
                          await context.read<AppsService>().addToCategory(selectedApplication, category);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
}
