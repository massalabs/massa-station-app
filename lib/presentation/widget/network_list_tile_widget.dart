// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/presentation/provider/setting_provider.dart';

class NetworkListTileWidget extends ConsumerWidget {
  const NetworkListTileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(settingProvider);
    return ListTile(
      leading: const Icon(Icons.hub_outlined),
      title: const Text('Network Type'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Buildnet"),
          Switch(
            value: setting.mainNetwork,
            onChanged: (bool enabled) {
              ref.read(settingProvider.notifier).changeNetwork(isMainNet: enabled);
            },
          ),
          const Text("Mainnet"),
        ],
      ),
    );
  }
}
