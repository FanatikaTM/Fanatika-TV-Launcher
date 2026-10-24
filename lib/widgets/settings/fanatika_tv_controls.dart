// TV remote-friendly controls for optional Fanatika features.
// All interactive rows use the same focus model as original Arc settings.
import 'package:flutter/material.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

class FanatikaTvControls {
  static Widget section(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
    child: Text(text.toUpperCase(), style: const TextStyle(
      fontSize: 12, letterSpacing: 1.5, color: Color(0xFF9FB8DF),
      fontWeight: FontWeight.w700)),
  );

  static Widget action({
    required IconData icon, required String title, required VoidCallback onPressed,
    String? subtitle, Widget? trailing, bool autofocus = false,
  }) => FocusableSettingsTile(
    autofocus: autofocus,
    leading: Icon(icon, color: const Color(0xFFC4D9FF)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    subtitle: subtitle == null ? null : Text(subtitle,
      style: const TextStyle(color: Colors.white70, fontSize: 12)),
    trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white54),
    onPressed: onPressed,
  );

  static Widget toggle({
    required String title, required bool value, required VoidCallback onPressed,
    String? subtitle, IconData icon = Icons.tune,
  }) => action(icon: icon, title: title,
    subtitle: subtitle ?? (value ? 'On' : 'Off'),
    trailing: Icon(value ? Icons.toggle_on : Icons.toggle_off,
      color: value ? const Color(0xFF70AFFE) : Colors.white54, size: 32),
    onPressed: onPressed);

  static Future<T?> choose<T>(BuildContext context, {
    required String title, required List<T> values, required String Function(T) label,
    T? current,
  }) => showDialog<T>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      content: SizedBox(
        width: 380, height: (values.length * 65.0).clamp(88.0, 440.0).toDouble(),
        child: ListView.builder(
          itemCount: values.length,
          itemBuilder: (_, index) {
            final value = values[index];
            return FocusableSettingsTile(
              autofocus: index == 0,
              title: Text(label(value), style: const TextStyle(fontSize: 16)),
              trailing: value == current
                ? const Icon(Icons.check_circle, color: Color(0xFF70AFFE))
                : null,
              onPressed: () => Navigator.pop(dialogContext, value),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel'))],
    ));
}
