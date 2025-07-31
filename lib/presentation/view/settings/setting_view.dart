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
import 'package:mug/service/provider.dart';

class SettingView extends ConsumerStatefulWidget {
  const SettingView({super.key});

  @override
  ConsumerState<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends ConsumerState<SettingView> {
  _SettingViewState();

  late TextEditingController _txFeeController;
  late TextEditingController _gasFeeController;
  bool _isTxFeeEditing = false;
  bool _isGasFeeEditing = false;

  @override
  void initState() {
    super.initState();
    final initialTransactionFee = ref.read(settingProvider).feeAmount;
    final initialGasFee = ref.read(settingProvider).gasAmount;
    _txFeeController = TextEditingController(text: initialTransactionFee.toStringAsFixed(4));
    _gasFeeController = TextEditingController(text: initialGasFee.toStringAsFixed(4));
  }

  @override
  Widget build(BuildContext context) {
    final minimumTxFee = ref.watch(settingProvider).feeAmount;
    final minimumGasFee = ref.watch(settingProvider).gasAmount;
    return Scaffold(
      body: CommonPadding(
        child: ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.gas_meter_outlined),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Max Gas Fee:"),
                  const HelpInfo(
                      message:
                          'Maximum Gas fee is the minimum amount of coin required to perform a smart contract transaction on the blockchain."'),
                  const SizedBox(width: 10),
                  // Form Field
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        _gasFeeController.text = ref.watch(settingProvider).gasAmount.toStringAsFixed(4);
                        return TextFormField(
                          controller: _gasFeeController,
                          enabled: _isGasFeeEditing,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: minimumGasFee.toStringAsFixed(4),
                          ),
                          autocorrect: true,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text("MAS"),
                ],
              ),
              trailing: IconButton(
                icon: Icon(_isGasFeeEditing ? Icons.save : Icons.edit),
                color: _isTxFeeEditing
                    ? const Color.fromARGB(255, 104, 191, 208)
                    : const Color.fromARGB(255, 246, 247, 247),
                onPressed: _toggleGasFeeEditMode,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.payment_outlined),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Min Tx Fee:"),
                  const HelpInfo(
                      message:
                          'Minimum Transaction fee is the minimum amount of coins required to perform a normal (non smart contract) transaction on the blockchain."'),
                  const SizedBox(width: 10),
                  // Form Field
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        _txFeeController.text = ref.watch(settingProvider).feeAmount.toStringAsFixed(4);
                        return TextFormField(
                          controller: _txFeeController,
                          enabled: _isTxFeeEditing,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: minimumTxFee.toStringAsFixed(4),
                          ),
                          autocorrect: true,
                        );
                      },
                    ),
                  ),
                  // Edit/Save Icon
                  const SizedBox(width: 2),
                  const Text("MAS"),
                ],
              ),
              trailing: IconButton(
                icon: Icon(_isTxFeeEditing ? Icons.save : Icons.edit),
                color: _isTxFeeEditing
                    ? const Color.fromARGB(255, 104, 191, 208)
                    : const Color.fromARGB(255, 246, 247, 247),
                onPressed: _toggleTxFeeEditMode,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.double_arrow),
              title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                const Text("Slippage:"),
                const HelpInfo(
                    message:
                        'Slippage is the difference between the expected price of a swapping ond DEX and the actual price.'),
                const SizedBox(width: 16),
                SlippageWidget(),
              ]),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                _showLogoutDialog();
              },
            ),
            const Divider(height: 1),
            const AboutWidget(),
          ],
        ),
      ),
    );
  }

  void _toggleGasFeeEditMode() {
    setState(() {
      if (_isGasFeeEditing) {
        final enteredValue = double.tryParse(_gasFeeController.text);
        if (enteredValue != null && enteredValue >= minimumFee * 10) {
          ref.read(settingProvider.notifier).changeGasFee(gasFeeAmount: enteredValue);
          informationSnackBarMessage(context, "The gas fee is changed!");
        }
      } else {
        final currentFee = ref.read(settingProvider).gasAmount;
        _gasFeeController.text = currentFee.toStringAsFixed(4);
      }
      _isGasFeeEditing = !_isGasFeeEditing;
    });
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
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
    _gasFeeController.dispose();
    super.dispose();
  }
}
