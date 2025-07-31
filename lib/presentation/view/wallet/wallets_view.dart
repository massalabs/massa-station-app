// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/presentation/provider/setting_provider.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/presentation/provider/wallet_selection_provider.dart';
import 'package:mug/presentation/view/wallet/wallet_view.dart';

// Project imports:
import 'package:mug/routes/routes_name.dart';
import 'package:mug/presentation/widget/widget.dart';
import 'package:mug/utils/number_helpers.dart';

class WalletsView extends ConsumerWidget {
  const WalletsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          return ref.read(walletListProvider.notifier).loadWallets();
        },
        child: walletState.when(
          data: (wallets) {
            if (wallets!.wallets.isEmpty) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        "It is very lonely here! No wallet found! You can create a new wallet or import an existing wallet."),
                  ),
                  _addImport(context, ref)
                ],
              );
            }
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(
                            "${formatNumber4(wallets.finalBalance)} MAS",
                            textAlign: TextAlign.center,
                          ),
                          subtitle: const Text("Total Balance", textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(formatNumber(wallets.rolls.toDouble()), textAlign: TextAlign.center),
                          subtitle: const Text("Total Rolls", textAlign: TextAlign.center),
                        ),
                      ),
                    )
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: wallets.wallets.length,
                    itemBuilder: (BuildContext context, int index) {
                      final wallet = wallets.wallets[index];
                      return GestureDetector(
                        onTap: () async {
                          final hasBalance =
                              wallet.addressInformation!.finalBalance >= ref.read(settingProvider).feeAmount;
                          final WalletViewArg walletViewArg = WalletViewArg(wallet.address, wallet.name, hasBalance);
                          ref.read(walletSelectionProvider.notifier).selectWallet(walletViewArg);
                        },
                        child: Card(
                          child: ListTile(
                            leading: SizedBox(
                              width: 50,
                              height: 50,
                              child: AddressIcon(wallet.address),
                            ),
                            title: Text(
                              wallet.name ?? wallet.address.substring(wallet.address.length - 4),
                              style: const TextStyle(fontSize: 20),
                            ),
                            trailing: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatNumber4(wallet.addressInformation!.finalBalance),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "MAS",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _addImport(context, ref)
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Connection error",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please check your internet connection",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(walletListProvider.notifier).loadWallets();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }

  Row _addImport(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.tonalIcon(
          onPressed: () async {
            await Navigator.pushNamed(
              context,
              WalletRoutes.importWallet,
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Import Wallet'),
          iconAlignment: IconAlignment.start,
        ),
        const SizedBox(width: 10.0),
        FilledButton.tonalIcon(
          onPressed: () async {
            await ref.watch(walletListProvider.notifier).createNewWallet();
          },
          icon: const Icon(Icons.account_balance_wallet),
          label: const Text('New Wallet'),
          iconAlignment: IconAlignment.start,
        ),
      ],
    );
  }
}
