// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mug/constants/asset_names.dart';
import 'package:mug/constants/constants.dart';
import 'package:mug/domain/entity/address_entity.dart';

// Project imports:
import 'package:mug/presentation/provider/address_provider.dart';
import 'package:mug/presentation/provider/screen_title_provider.dart';
import 'package:mug/presentation/provider/setting_provider.dart';
import 'package:mug/presentation/provider/transfer_provider.dart';
import 'package:mug/presentation/state/transfer_state.dart';
import 'package:mug/presentation/widget/widget.dart';
import 'package:mug/utils/number_helpers.dart';
import 'package:mug/utils/string_helpers.dart';
import 'package:mug/utils/validate_address.dart';

class TransferView extends ConsumerStatefulWidget {
  final AddressEntity addressEntity;
  const TransferView(this.addressEntity, {super.key});

  @override
  ConsumerState<TransferView> createState() => _TransferViewState();
}

class _TransferViewState extends ConsumerState<TransferView> {
  late final TextEditingController amountController;
  late final TextEditingController addressController;
  late final FocusNode amountFocusNode;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _showWarning = true;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    addressController = TextEditingController();
    amountFocusNode = FocusNode();

    // Listen for changes to update warning visibility
    amountController.addListener(_updateWarningVisibility);
    addressController.addListener(_updateWarningVisibility);

    // Reset transfer state when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transferProvider.notifier).resetState();
    });
  }

  @override
  void dispose() {
    amountController.removeListener(_updateWarningVisibility);
    addressController.removeListener(_updateWarningVisibility);
    amountController.dispose();
    addressController.dispose();
    amountFocusNode.dispose();
    super.dispose();
  }

  void _updateWarningVisibility() {
    setState(() {
      _showWarning = addressController.text.isEmpty || amountController.text.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionFee = ref.watch(settingProvider).feeAmount;

    final screenTitle = ref.watch(screenTitleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/icons/massa_station_full.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: CommonPadding(
          child: RefreshIndicator(
            onRefresh: () {
              return ref.read(addressProvider.notifier).getAddress(widget.addressEntity.address, false);
            },
            child: Consumer(
              builder: (context, ref, child) {
                // var isDarkTheme = ref.watch(settingProvider).darkTheme;
                return switch (ref.watch(transferProvider)) {
                  TransferInitial() => Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        CustomLabelWidget(
                            label: "From",
                            value: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(shortenString(widget.addressEntity.address, 26), style: const TextStyle(fontSize: 20)),
                              IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: widget.addressEntity.address)).then((result) {
                                      informationSnackBarMessage(context, "Address copied!");
                                    });
                                  },
                                  icon: const Icon(Icons.copy)),
                            ])),
                        const SizedBox(height: 10),
                        CustomLabelWidget(
                          label: "To",
                          value: AddressSelectorWidget(
                              currentAddress: widget.addressEntity.address, addressController: addressController),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Form(
                                            key: formKey,
                                            child: TextFormField(
                                              enabled: true,
                                              controller: amountController,
                                              focusNode: amountFocusNode,
                                              onChanged: (value) {},
                                              decoration: const InputDecoration(
                                                hintText: '0.0000',
                                                border: InputBorder.none,
                                              ),
                                              style: const TextStyle(fontSize: 20),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d*)?')),
                                              ],
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter a value';
                                                }
                                                try {
                                                  final enteredValue = double.parse(value);
                                                  if (enteredValue > widget.addressEntity.finalBalance - transactionFee) {
                                                    return 'Value should not exceed ${widget.addressEntity.finalBalance - transactionFee}';
                                                  }
                                                } catch (e) {
                                                  return 'Please enter a valid decimal number';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ),
                                        const Text("MAS", style: TextStyle(fontSize: 20)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        final availableBalance = widget.addressEntity.finalBalance - transactionFee;
                                        if (availableBalance > 0) {
                                          FocusScope.of(context).unfocus();
                                          Future.delayed(const Duration(milliseconds: 50), () {
                                            amountController.text = formatNumber4(availableBalance);
                                            amountFocusNode.requestFocus();
                                          });
                                        }
                                      },
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          "Balance: ${formatNumber4(widget.addressEntity.finalBalance - transactionFee)} MAS",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 46, 53, 56),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Amount"),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${transactionFee} MAS",
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 46, 53, 56),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Fee"),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Only show warning if address or amount is empty
                        if (_showWarning)
                          const InformationCardWidget(
                              message: "Please confirm the amount and recipient address before transferring your fund"),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                if (!isAddressValid(addressController.text)) {
                                  informationSnackBarMessage(context, 'Invalid address. Please enter a valid address');
                                  return;
                                }

                                if (!formKey.currentState!.validate() ||
                                    addressController.text.isEmpty ||
                                    addressController.text == widget.addressEntity.address) {
                                  informationSnackBarMessage(context, 'One of the entries is invalid. Try again!');
                                  return;
                                }
                                final amount = double.parse(amountController.text);

                                final recipientAddress = addressController.text;
                                await ref
                                    .read(transferProvider.notifier)
                                    .transfer(widget.addressEntity.address, recipientAddress, amount);
                              },
                              icon: const Icon(Icons.arrow_outward, size: 28),
                              label: const Text('Send', style: TextStyle(fontSize: 18)),
                              iconAlignment: IconAlignment.start,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40), // Extra padding for phone overlay menu
                      ],
                    ),
                  TransferLoading() => const CircularProgressIndicator(),
                  TransferSubmitting(
                    sendingAddress: final sendingAddress,
                    recipientAddress: final recipientAddress,
                    amount: final amount,
                    fee: final fee,
                  ) =>
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        const Text("Submitting transfer...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("From: ${shortenString(sendingAddress, 26)}"),
                                const SizedBox(height: 8),
                                Text("To: ${shortenString(recipientAddress, 26)}"),
                                const SizedBox(height: 8),
                                Text("Amount: $amount MAS"),
                                const SizedBox(height: 8),
                                Text("Fee: $fee MAS"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  TransferSubmitted(
                    sendingAddress: final sendingAddress,
                    recipientAddress: final recipientAddress,
                    amount: final amount,
                    fee: final fee,
                    operationId: final operationId,
                  ) =>
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        const Text("Transfer submitted!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("From: ${shortenString(sendingAddress, 26)}"),
                                const SizedBox(height: 8),
                                Text("To: ${shortenString(recipientAddress, 26)}"),
                                const SizedBox(height: 8),
                                Text("Amount: $amount MAS"),
                                const SizedBox(height: 8),
                                Text("Fee: $fee MAS"),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text("Operation ID: ${shortenString(operationId, 26)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  TransferWaitingConfirmation(
                    sendingAddress: final sendingAddress,
                    recipientAddress: final recipientAddress,
                    amount: final amount,
                    fee: final fee,
                    operationId: final operationId,
                  ) =>
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        const Text("Waiting for inclusion in block", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("From: ${shortenString(sendingAddress, 26)}"),
                                const SizedBox(height: 8),
                                Text("To: ${shortenString(recipientAddress, 26)}"),
                                const SizedBox(height: 8),
                                Text("Amount: $amount MAS"),
                                const SizedBox(height: 8),
                                Text("Fee: $fee MAS"),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text("Operation ID: ${shortenString(operationId, 26)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text("⏳ Waiting for transaction to be included in a block...", style: TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  TransferIncludedInBlock(
                    sendingAddress: final sendingAddress,
                    recipientAddress: final recipientAddress,
                    amount: final amount,
                    fee: final fee,
                    operationId: final operationId,
                    blockId: final blockId,
                  ) =>
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        const Text("Waiting for finalization", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("From: ${shortenString(sendingAddress, 26)}"),
                                const SizedBox(height: 8),
                                Text("To: ${shortenString(recipientAddress, 26)}"),
                                const SizedBox(height: 8),
                                Text("Amount: $amount MAS"),
                                const SizedBox(height: 8),
                                Text("Fee: $fee MAS"),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text("Operation ID: ${shortenString(operationId, 26)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text("Block ID: ${shortenString(blockId, 26)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text("✅ Transaction included in block, waiting for finalization...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  TransferSuccess(transferEntity: final transfersEntity) => Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const SuccessInformationWidget(message: "Fund transfered successfully!"),
                        const SizedBox(height: 20),
                        CustomLabelWidget(
                            label: "From",
                            value: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(shortenString(transfersEntity.sendingAddress!, 26),
                                  style: const TextStyle(fontSize: 20)),
                              IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: widget.addressEntity.address)).then((result) {
                                      informationSnackBarMessage(context, "Address copied!");
                                    });
                                  },
                                  icon: const Icon(Icons.copy)),
                            ])),
                        const SizedBox(height: 10),
                        CustomLabelWidget(
                            label: "To",
                            value: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(shortenString(transfersEntity.recipientAddress!, 26),
                                  style: const TextStyle(fontSize: 20)),
                              IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: widget.addressEntity.address)).then((result) {
                                      informationSnackBarMessage(context, "Address copied!");
                                    });
                                  },
                                  icon: const Icon(Icons.copy)),
                            ])),
                        const SizedBox(height: 10),
                        CustomLabelWidget(
                          label: "Amount",
                          value: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: Text(
                                transfersEntity.amount.toString(),
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
                          label: "Fee",
                          value: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: Text(
                                transactionFee.toString(),
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
                              shortenString(transfersEntity.operationID!, 26),
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 18),
                            ),
                            IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: widget.addressEntity.address)).then((result) {
                                    informationSnackBarMessage(context, 'Operation ID copied');
                                  });
                                },
                                icon: const Icon(Icons.copy)),
                          ]),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            ref.read(transferProvider.notifier).resetState();
                            // Refresh wallet data when returning
                            ref.read(addressProvider.notifier).getAddress(widget.addressEntity.address, false);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          iconAlignment: IconAlignment.start,
                        ),
                      ],
                    ),
                  TransferFailure(message: final message) => Text(message),
                };
              },
            ),
          ),
        ),
      ),
    );
  }
}
