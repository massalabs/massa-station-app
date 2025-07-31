// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/presentation/provider/setting_provider.dart';

class ThemeListTileWidget extends ConsumerWidget {
  const ThemeListTileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(settingProvider);
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: const Text('Dark theme'),
      trailing: Switch(
        value: setting.darkTheme,
        onChanged: (bool enabled) {
          ref.read(settingProvider.notifier).changeTheme(isDarkTheme: enabled);
        },
      ),
    );
  }
}
