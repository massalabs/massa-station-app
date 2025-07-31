// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mug/constants/asset_names.dart';

// Project imports:
import 'package:mug/presentation/provider/setting_provider.dart';
import 'package:mug/presentation/provider/swap_provider.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/presentation/state/swap_state.dart';
import 'package:mug/presentation/widget/widget.dart';
import 'package:mug/routes/routes.dart';
import 'package:mug/utils/number_helpers.dart';
import 'package:mug/utils/string_helpers.dart';

class SwapView extends ConsumerStatefulWidget {
  final String accountAddress;
  const SwapView(this.accountAddress, {super.key});

  @override
  ConsumerState<SwapView> createState() => _DexViewState();
}

class _DexViewState extends ConsumerState<SwapView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      ref.read(swapProvider.notifier).initialLoad(widget.accountAddress);
    });
  }

  final TextEditingController _fromAmountController = TextEditingController();
  final TextEditingController _toAmountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final swapState = ref.watch(swapProvider);
    final notifier = ref.read(swapProvider.notifier);
    return CommonPadding(
      child: RefreshIndicator(
        onRefresh: () {
          return ref.read(swapProvider.notifier).initialLoad(widget.accountAddress);
        },
        child: Consumer(
          builder: (context, ref, child) {
            var isDarkTheme = ref.watch(settingProvider).darkTheme;
            return switch (swapState.status) {
                SwapStatus.loading => Container(
                    color: Colors.black.withOpacity(0.0), // Semi-transparent overlay
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                SwapStatus.swap => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomLabelWidget(
                              label: "Account Address",
                              value: Text(widget.accountAddress, style: const TextStyle(fontSize: 20))),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[700]!, // Border color
                                  width: 1.5, // Border width
                                ),
                                borderRadius: BorderRadius.circular(12), // Rounded corners
                              ),
                              child: Row(
                                children: [
                                  // TextFormField
                                  Expanded(
                                    child: TextFormField(
                                      enabled: true,
                                      controller: _fromAmountController,
                                      onChanged: (value) {
                                        final value1 = double.parse(_fromAmountController.text.replaceAll(',', ''));
                                        _toAmountController.text = notifier.computeExchangeResult(value1).toString();
                                      },
                                      //keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '0.0000',
                                        border: InputBorder.none, // Removes internal border for seamless look
                                      ),
                                      style: const TextStyle(color: Colors.white, fontSize: 26),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?')),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10), // Add some spacing between dropdown and text box

                                  // DropdownButton
                                  Column(
                                    children: [
                                      DropdownButton<String>(
                                        value: swapState.selectedDropdown1,
                                        items: _getDropdownItems(swapState.allItems),
                                        onChanged: (String? newValue) {
                                          if (newValue == swapState.selectedDropdown2) {
                                            // If user selects the same coin as dropdown2, swap them
                                            notifier.flipTokens();
                                            _fromAmountController.clear();
                                            _toAmountController.clear();
                                          } else {
                                            notifier.selectDropdown1(newValue);
                                          }
                                        },
                                        underline: const SizedBox(), // Removes the underline
                                        style: const TextStyle(color: Colors.white, fontSize: 16), // Text styling
                                        dropdownColor:
                                            Colors.grey[900], // Optional: Set dropdown background color for dark theme
                                      ),
                                      Text(
                                        "Balance: ${formatNumber4(swapState.balance1!)}",
                                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: FloatingActionButton(
                              onPressed: () {
                                notifier.flipTokens();
                                _fromAmountController.clear();
                                _toAmountController.clear();
                              },
                              backgroundColor: isDarkTheme ? ThemeData.dark().focusColor : ThemeData.light().focusColor,
                              elevation: 2.0,
                              child: const Icon(Icons.swap_vert, size: 28, color: Colors.white),
                            ),
                          ),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[700]!, // Border color
                                  width: 1.5, // Border width
                                ),
                                borderRadius: BorderRadius.circular(12), // Rounded corners
                              ),
                              child: Row(
                                children: [
                                  // TextFormField
                                  Expanded(
                                    child: TextFormField(
                                      enabled: false,
                                      controller: _toAmountController,
                                      //onChanged: (value) {},
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '0.0000',
                                        border: InputBorder.none, // Removes internal border for seamless look
                                      ),
                                      style: const TextStyle(color: Colors.white, fontSize: 26),
                                      inputFormatters: [
                                        TextInputFormatter.withFunction(
                                            (TextEditingValue oldValue, TextEditingValue newValue) {
                                          var formatter = NumberFormat('###,###.####', 'en_US');
                                          var value = formatter.tryParse(newValue.text) ?? 0;
                                          if (newValue.text.endsWith('.') &&
                                              '.'.allMatches(newValue.text).length == 1) {
                                            return newValue;
                                          }
                                          return TextEditingValue(
                                            text: formatter.format(value),
                                          );
                                        })
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    children: [
                                      DropdownButton<String>(
                                        value: swapState.selectedDropdown2,
                                        items: _getDropdownItems(swapState.allItems),
                                        onChanged: (String? newValue) {
                                          if (newValue == swapState.selectedDropdown1) {
                                            // If user selects the same coin as dropdown1, swap them
                                            notifier.flipTokens();
                                            _fromAmountController.clear();
                                            _toAmountController.clear();
                                          } else {
                                            notifier.selectDropdown2(newValue);
                                          }
                                        },
                                        underline: const SizedBox(), // Removes the underline
                                        style: const TextStyle(color: Colors.white, fontSize: 16), // Text styling
                                        dropdownColor:
                                            Colors.grey[900], // Optional: Set dropdown background color for dark theme
                                      ),
                                      Text(
                                        "Balance: ${formatNumber4(swapState.balance2!)}",
                                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text("1 MAS = ${swapState.exchangeRate} ${notifier.getOtherTokenName()}"),
                          ButtonWidget(
                            isDarkTheme: isDarkTheme,
                            text: "Swap",
                            onClicked: () {
                              final value1 = double.parse(_fromAmountController.text.replaceAll(',', ''));
                              final value2 = double.parse(_toAmountController.text.replaceAll(',', ''));
                              notifier.swap(value1, value2);
                              if (swapState.showNotification!) {
                                informationSnackBarMessage(context, swapState.notificationMessage);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                SwapStatus.success => Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const SuccessInformationWidget(message: "Swap completed successfully!"),
                      const SizedBox(height: 20),
                      CustomLabelWidget(
                        label: "Swapped from",
                        value: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                                child: Text(
                              _fromAmountController.text,
                              style: const TextStyle(fontSize: 26),
                            )),
                            const SizedBox(width: 10), // Add some spacing between dropdown and text box
                            Row(
                              children: [
                                SvgPicture.asset(tokenItems[swapState.selectedDropdown1]!.iconPath,
                                    semanticsLabel: swapState.selectedDropdown1, height: 40.0, width: 40.0),
                                const SizedBox(width: 10),
                                Text(swapState.selectedDropdown1!, style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomLabelWidget(
                        label: "Swapped to",
                        value: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                                child: Text(
                              _toAmountController.text,
                              style: const TextStyle(fontSize: 26),
                            )),
                            const SizedBox(width: 10), // Add some spacing between dropdown and text box
                            Row(
                              children: [
                                SvgPicture.asset(tokenItems[swapState.selectedDropdown2]!.iconPath,
                                    semanticsLabel: swapState.selectedDropdown2, height: 40.0, width: 40.0),
                                const SizedBox(width: 10),
                                Text(swapState.selectedDropdown2!, style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomLabelWidget(
                        label: "Transaction Fee ",
                        value: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                                child: Text(
                              ref.watch(settingProvider).feeAmount.toString(),
                              style: const TextStyle(fontSize: 26),
                            )),
                            const SizedBox(width: 10), // Add some spacing between dropdown and text box
                            Row(
                              children: [
                                SvgPicture.asset(AssetName.mas, semanticsLabel: "MAS", height: 40.0, width: 40.0),
                                const SizedBox(width: 10),
                                const Text("MAS", style: TextStyle(fontSize: 24))
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomLabelWidget(
                        label: "Operation ID",
                        value: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            shortenString(swapState.notificationMessage!, 26),
                            textAlign: TextAlign.left,
                            style: const TextStyle(fontSize: 18),
                          ),
                          IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: swapState.notificationMessage!)).then((result) {
                                  informationSnackBarMessage(context, 'Operation ID copied');
                                });
                              },
                              icon: const Icon(Icons.copy)),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          _fromAmountController.clear();
                          _toAmountController.clear();
                          await ref.read(swapProvider.notifier).initialLoad(widget.accountAddress);
                          await ref.read(walletListProvider.notifier).loadWallets();
                          // Stay on the same wallet, don't navigate away
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        iconAlignment: IconAlignment.start,
                      ),
                    ],
                  ),
                SwapStatus.error => const Text(
                    "Could not open the swap view, due to insufficient funds for covering gass and transaction fee! You need to have a balance of at least 10 MAS in your wallet."),
              };
            },
          ),
        ),
      );
  }

  List<DropdownMenuItem<String>> _getDropdownItems(Map<String, DropdownItem> items) {
    return items.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Row(
          children: [
            SvgPicture.asset(entry.value.iconPath, semanticsLabel: entry.key, height: 24.0, width: 24.0),
            const SizedBox(width: 10),
            Text(entry.key),
          ],
        ),
      );
    }).toList();
  }
}
