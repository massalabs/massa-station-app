import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/presentation/provider/wallet_provider.dart';
import 'package:mug/presentation/widget/information_snack_message.dart';

class RenameWalletBottomSheet extends ConsumerWidget {
  final String address;
  const RenameWalletBottomSheet({required this.address, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("RENAME WALLET", style: TextStyle(fontSize: 20, color: Colors.blue)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter a new name',
                ),
              ),
              const SizedBox(height: 16.0),
              FilledButton.tonalIcon(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    try {
                      await ref.read(walletProvider.notifier).renameWallet(address, controller.text);
                      informationSnackBarMessage(context, 'Wallet renamed!');
                      return Navigator.of(context).pop(controller.text);
                    } catch (e) {
                      informationSnackBarMessage(context, 'Error occured while saving the wallet name');
                      return Navigator.of(context).pop();
                    }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                iconAlignment: IconAlignment.start,
              ),
            ],
          ),
        ));
  }
}
