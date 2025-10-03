// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/presentation/provider/setting_provider.dart';
import 'package:mug/presentation/widget/help_information_widget.dart';

// Project imports:
import 'package:mug/presentation/widget/widget.dart';
import 'package:mug/routes/routes.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';

class SettingView extends ConsumerStatefulWidget {
  const SettingView({super.key});

  @override
  ConsumerState<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends ConsumerState<SettingView> {
  _SettingViewState();

  late TextEditingController _txFeeController;
  bool _isTxFeeEditing = false;

  @override
  void initState() {
    super.initState();
    final initialTransactionFee = ref.read(settingProvider).feeAmount;
    _txFeeController = TextEditingController(text: initialTransactionFee.toStringAsFixed(4));
  }

  @override
  Widget build(BuildContext context) {
    final minimumTxFee = ref.watch(settingProvider).feeAmount;
    return Scaffold(
      body: CommonPadding(
        child: ListView(
          children: <Widget>[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.payment_outlined, size: 20),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tx Fee:", style: TextStyle(fontSize: 13)),
                  const HelpInfo(
                      message:
                          'Transaction fee is the amount of coins paid to the network for processing transactions.'),
                  const SizedBox(width: 4),
                  // Form Field
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        _txFeeController.text = ref.watch(settingProvider).feeAmount.toStringAsFixed(4);
                        return TextFormField(
                          controller: _txFeeController,
                          enabled: _isTxFeeEditing,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: minimumTxFee.toStringAsFixed(4),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          autocorrect: true,
                        );
                      },
                    ),
                  ),
                  // Edit/Save Icon
                  const SizedBox(width: 2),
                  const Text("MAS", style: TextStyle(fontSize: 11)),
                ],
              ),
              trailing: IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(_isTxFeeEditing ? Icons.save : Icons.edit),
                color: _isTxFeeEditing
                    ? const Color.fromARGB(255, 104, 191, 208)
                    : const Color.fromARGB(255, 246, 247, 247),
                onPressed: _toggleTxFeeEditMode,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.double_arrow, size: 20),
              title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                const Text("Slippage:", style: TextStyle(fontSize: 13)),
                const HelpInfo(
                    message:
                        'Maximum price difference you allow between expected and actual swap price.'),
                const SizedBox(width: 8),
                SlippageWidget(),
              ]),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.timer_outlined, size: 20),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Timeout:", style: TextStyle(fontSize: 13)),
                  const HelpInfo(
                      message:
                          'App will automatically lock after this period of inactivity to protect your wallet.'),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final currentIndex = ref.read(localStorageServiceProvider).inactivityTimeoutIndex;
                        final timeoutOptions = [30, 60, 120, 180, 300, 600, 900];
                        final timeoutLabels = ['30s', '1m', '2m', '3m', '5m', '10m', '15m'];

                        return DropdownButton<int>(
                          value: currentIndex,
                          isExpanded: true,
                          isDense: true,
                          style: const TextStyle(fontSize: 13),
                          items: List.generate(timeoutOptions.length, (index) {
                            return DropdownMenuItem<int>(
                              value: index,
                              child: Text(timeoutLabels[index], style: const TextStyle(fontSize: 13)),
                            );
                          }),
                          onChanged: (newIndex) async {
                            if (newIndex != null && newIndex != currentIndex) {
                              await ref.read(localStorageServiceProvider).setInactivityTimeoutIndex(index: newIndex);
                              if (mounted) {
                                informationSnackBarMessage(context, "Timeout changed to ${timeoutLabels[newIndex]}. Will apply on next unlock.");
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Show authentication mode info
            if (ref.watch(localStorageServiceProvider).authenticationMode == AuthenticationMode.biometricOnly)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.fingerprint, size: 20),
                title: const Text("Authentication: Biometric Only", style: TextStyle(fontSize: 13)),
                subtitle: const Text("Unlock with biometric or device PIN", style: TextStyle(fontSize: 11)),
              ),
            if (ref.watch(localStorageServiceProvider).authenticationMode == AuthenticationMode.passphrase)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.password, size: 20),
                title: const Text("Authentication: Passphrase", style: TextStyle(fontSize: 13)),
                subtitle: const Text("Unlock with passphrase only", style: TextStyle(fontSize: 11)),
              ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.logout, color: Colors.orange, size: 20),
              title: const Text(
                "Lock App",
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
              onTap: () {
                _lockApp();
              },
            ),
            const Divider(height: 1),
            const AboutWidget(),
          ],
        ),
      ),
    );
  }

  void _toggleTxFeeEditMode() {
    setState(() {
      if (_isTxFeeEditing) {
        final enteredValue = double.tryParse(_txFeeController.text);
        if (enteredValue != null && enteredValue >= minimumFee) {
          ref.read(settingProvider.notifier).changeTxFee(feeAmount: enteredValue);
          informationSnackBarMessage(context, "The transaction fee changed!");
        }
      } else {
        // Update the TextField with the latest provider value
        final currentFee = ref.read(settingProvider).feeAmount;
        _txFeeController.text = currentFee.toStringAsFixed(4);
      }
      _isTxFeeEditing = !_isTxFeeEditing;
    });
  }

  void _showLockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lock App'),
          content: const Text('Are you sure you want to lock the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _lockApp();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Lock'),
            ),
          ],
        );
      },
    );
  }

  void _lockApp() {
    ref.read(localStorageServiceProvider).setLoginStatus(false);
    Navigator.pushNamedAndRemoveUntil(
      context,
      AuthRoutes.authWall,
      (Route<dynamic> route) => false,
      arguments: false,
    );
  }


  @override
  void dispose() {
    _txFeeController.dispose();
    super.dispose();
  }
}
