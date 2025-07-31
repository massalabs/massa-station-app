// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/presentation/provider/domain_provider.dart';
import 'package:mug/presentation/provider/wallet_provider.dart';
import 'package:mug/presentation/view/explorer/mns_view.dart';

// Project imports:
import 'package:mug/presentation/widget/information_snack_message.dart';
import 'package:mug/presentation/widget/label_card.dart';
import 'package:mug/routes/routes_name.dart';
import 'package:mug/utils/number_helpers.dart';

class MNSWidget extends ConsumerWidget {
  final String domainName;
  final double domainPrice;
  const MNSWidget({required this.domainName, required this.domainPrice, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultWallet = ref.read(walletProvider.notifier).getDefaultWalletInformation(false);
    return FutureBuilder(
        future: defaultWallet,
        builder: (context, snapshot) {
          if (snapshot.hasData && domainPrice != 0.0) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  LabelCard(
                    labelText: "Domain",
                    valueText: "$domainName.massa",
                    leadingIcon: const Icon(Icons.language, size: 30),
                  ),
                  const LabelCard(
                    labelText: "Status",
                    valueText: "Available for purchase",
                    leadingIcon: Icon(Icons.check, size: 30),
                  ),
                  LabelCard(
                    labelText: "Price",
                    valueText: "${formatNumber2(domainPrice)} MAS",
                    leadingIcon: const Icon(Icons.attach_money, size: 30),
                  ),
                  LabelCard(
                    labelText: "Available Balance (default account)",
                    valueText: "${formatNumber2(snapshot.data!.finalBalance)} MAS",
                    leadingIcon: const Icon(Icons.credit_card, size: 30),
                  ),
                  if (domainPrice + toMAS(BigInt.from(GasLimit.MAX_GAS_EXECUTE_SC.value)) < snapshot.data!.finalBalance)
                    FilledButton.tonalIcon(
                      label: const Text("Buy"),
                      icon: const Icon(Icons.language),
                      onPressed: () async {
                        informationSnackBarMessage(context, "Processing your request, please wait!");
                        final result = await ref.read(domainProvider.notifier).buyDomain(domainName, domainPrice);
                        if (result.$2 && result.$1.startsWith("O")) {
                          final arg = MNSArguments(
                              isSuccess: true,
                              domainName: domainName,
                              ownerAddress: snapshot.data!.address,
                              domainPrice: domainPrice,
                              operationID: result.$1);
                          Navigator.pop(context);
                          await Navigator.pushNamed(
                            context,
                            ExploreRoutes.mns,
                            arguments: arg,
                          );
                        }
                      },
                    ),
                  if (domainPrice + toMAS(BigInt.from(GasLimit.MAX_GAS_EXECUTE_SC.value)) >
                      (snapshot.data!.finalBalance))
                    const LabelCard(
                      labelText: "Warning!",
                      valueText: "Insufficient balance for buying domain and cover gas fee!",
                      leadingIcon: Icon(
                        Icons.warning,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
            );
          }
          return const CircularProgressIndicator();
        });
  }
}
