// Updates are separate from customization. User-approved installation only.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/fanatika_release_checker.dart';
import 'package:flauncher/providers/fanatika_backup_service.dart';
import 'package:flauncher/widgets/fanatika_update_dialog.dart';
import 'package:flauncher/widgets/settings/fanatika_tv_controls.dart';
import 'package:flauncher/flauncher_channel.dart';

class FanatikaUpdatesPage extends StatefulWidget {
  static const routeName = 'fanatika_updates';
  const FanatikaUpdatesPage({super.key});
  @override State<FanatikaUpdatesPage> createState() => _FanatikaUpdatesPageState();
}
class _FanatikaUpdatesPageState extends State<FanatikaUpdatesPage> {
  String message = '';
  bool busy = false;
  Future<void> checkNow() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await FanatikaReleaseChecker.check(releaseRepo: context.read<SettingsService>().fanatikaReleaseRepo);
      if (!mounted) return;
      setState(() => message = result.message);
      if (result.updateAvailable) {
        await FanatikaUpdateDialogs.offer(context, result);
      } else {
        await FanatikaUpdateDialogs.showStatus(context, result.message);
      }
    } catch (e) { if (mounted) setState(() => message = 'Update check unavailable: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> configureRepo() async {
    final settings = context.read<SettingsService>();
    final controller = TextEditingController(text: settings.fanatikaReleaseRepo);
    final repo = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Public APK release repository'),
      content: TextField(controller: controller, autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save'))],
    ));
    controller.dispose();
    if (repo != null && mounted) {
      try { await settings.setFanatikaReleaseRepo(FanatikaReleaseChecker.normalizedRepo(repo)); }
      catch (e) { setState(() => message = '$e'); }
    }
  }
  Future<void> installLocal() async {
    final file = await FanatikaBackupService.selectReviewedUpdate();
    if (file == null || !mounted) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Install selected update APK?'),
      content: const Text('Android verifies signing compatibility. Review before installation; your HOME selection will not be changed.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx,false),child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx,true),child: const Text('Continue'))],
    )) ?? false;
    if (ok) {
      try { await FLauncherChannel().installApk(file); }
      catch (e) { if (mounted) setState(() => message = 'Installer error: $e'); }
    }
  }
  @override Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    return Column(children: [
      const Padding(padding: EdgeInsets.all(12), child: Text('Updates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      const Divider(height: 1),
      Expanded(child: ListView(children: [
        FanatikaTvControls.action(icon: Icons.update, title: 'Automatic update checks',
          subtitle: s.fanatikaUpdateCheckDays == 0 ? 'Off' : 'Every ${s.fanatikaUpdateCheckDays} days',
          autofocus: true, onPressed: () async {
            final days = await FanatikaTvControls.choose<int>(context, title: 'Check for updates',
              values: SettingsService.fanatikaUpdateCadenceChoices, current: s.fanatikaUpdateCheckDays,
              label: (v) => v == 0 ? 'Off' : 'Every $v days');
            if (days != null) await s.setFanatikaUpdateCheckDays(days);
          }),
        FanatikaTvControls.action(icon: Icons.public, title: 'Public release source',
          subtitle: 'GitHub Releases · Configure source', onPressed: configureRepo),
        FanatikaTvControls.action(icon: Icons.new_releases, title: 'Check / download / install update',
          subtitle: 'Verify APK signature and approve installation', onPressed: checkNow),
        FanatikaTvControls.action(icon: Icons.file_open, title: 'Install local update APK',
          subtitle: 'Includes APK files selected from USB when a compatible picker is available', onPressed: installLocal),
        if (busy) const LinearProgressIndicator(),
        if (message.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(message)),
      ])),
    ]);
  }
}
