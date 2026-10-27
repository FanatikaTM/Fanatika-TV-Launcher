// User-approved Android Storage Access Framework USB importing.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/fanatika_backup_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/settings/fanatika_tv_controls.dart';

class FanatikaUsbPage extends StatefulWidget {
  static const routeName = 'fanatika_usb';
  const FanatikaUsbPage({super.key});
  @override State<FanatikaUsbPage> createState() => _FanatikaUsbPageState();
}
class _FanatikaUsbPageState extends State<FanatikaUsbPage> {
  final channel = FLauncherChannel();
  List<Map<String,dynamic>> drives = [];
  String status = 'Connect a USB drive, then select Detect USB.';
  bool busy = false;
  Future<void> run(Future<void> Function() operation) async {
    if (busy) return;
    setState(() => busy = true);
    try { await operation(); }
    catch (e) { if (mounted) setState(() => status = 'USB operation failed: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> detect() => run(() async {
    final result = await channel.fanatikaUsbVolumes();
    if (mounted) setState(() {
      drives = result;
      status = result.isEmpty ? 'Android reports no removable storage. Check TV USB settings.'
        : '${result.length} removable storage volume(s) detected.';
    });
  });
  Future<void> importImage() => run(() async {
    final result = await channel.fanatikaUsbChoose('wallpaper');
    if (mounted) setState(() => status = result['message']?.toString() ?? 'No image selected.');
  });
  Future<void> importBackup() => run(() async {
    final result = await channel.fanatikaUsbChoose('backup');
    if (!mounted) return;
    if (result['ok'] != true) {
      setState(() => status = result['message']?.toString() ?? 'No backup selected'); return;
    }
    final raw = result['backup'];
    if (raw is! String || raw.length > 2000000) throw const FormatException('Invalid backup size');
    final data = FanatikaBackupService.validateImportedJson(raw);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Restore backup from USB?'),
      content: Text('Restore ${(data['favorites'] as List).length} Favorites and compatible preferences? A safety backup is required first.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('Restore'))],
    )) ?? false;
    if (!ok || !mounted) return;
    final settings = context.read<SettingsService>();
    final apps = context.read<AppsService>();
    final safety = await FanatikaBackupService.export(settings, apps);
    if (!safety) { setState(() => status = 'Safety backup failed: no settings were overwritten.'); return; }
    await FanatikaBackupService.restore(data, settings, apps);
    if (mounted) setState(() => status = 'Backup restored. Restart the launcher to refresh the layout.');
  });
  @override Widget build(BuildContext context) => Column(children: [
    const Padding(padding: EdgeInsets.all(12), child: Text('USB storage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Divider(height: 1),
    Expanded(child: ListView(children: [
      FanatikaTvControls.action(icon: Icons.usb, title: 'Detect USB storage', autofocus: true,
        subtitle: 'Shows removable volumes Android can see', onPressed: detect),
      for (final drive in drives) ListTile(
        title: Text(drive['description']?.toString() ?? 'USB drive'),
        subtitle: Text(drive['state']?.toString() ?? 'Unknown state')),
      FanatikaTvControls.action(icon: Icons.wallpaper, title: 'Import USB wallpaper',
        subtitle: 'Choose JPG/PNG/WEBP, up to 40 MB, then select in Wallpaper settings', onPressed: importImage),
      FanatikaTvControls.action(icon: Icons.settings_backup_restore, title: 'Restore backup from USB',
        subtitle: 'Choose settings backup JSON; confirmation and safety backup required', onPressed: importBackup),
      const Padding(padding: EdgeInsets.all(12), child: Text(
        'USB import uses the Android document picker. Some Xiaomi firmware does not provide one; '
        'in that case, install a trusted file manager or transfer with ADB. No root access is used.',
        style: TextStyle(color: Colors.white70))),
      if (busy) const LinearProgressIndicator(),
      Padding(padding: const EdgeInsets.all(12), child: Text(status)),
    ])),
  ]);
}
