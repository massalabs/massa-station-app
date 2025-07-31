// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/presentation/provider/setting_provider.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/presentation/widget/information_snack_message.dart';

// Project imports:
import 'package:mug/routes/routes_name.dart';
import 'package:mug/presentation/widget/address_icon.dart';
import 'package:mug/utils/number_helpers.dart';

class DexView extends ConsumerWidget {
  const DexView({super.key});

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
              return const Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No wallet is created.. please navigate to wallet tab to create one."),
                  ),
                ],
              );
            }
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Select Wallet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: wallets.wallets.length,
                    itemBuilder: (BuildContext context, int index) {
                      final wallet = wallets.wallets[index];
                      return GestureDetector(
                        onTap: () async {
                          if (wallet.addressInformation!.finalBalance < ref.read(settingProvider).feeAmount) {
                            informationSnackBarMessage(context, "Wallet balance is less than the required fee amount");
                            return;
                          }
                          await Navigator.pushNamed(
                            context,
                            DexRoutes.swap,
                            arguments: wallet.address,
                          );
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
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: Text("An error has occurred, please try again later or report the issue to Massa Team"),
          )),
        ),
      ),
    );
  }
}
