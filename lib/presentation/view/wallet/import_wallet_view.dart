import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/presentation/widget/information_card_widget.dart';
import 'package:mug/presentation/widget/information_snack_message.dart';

class ImportWalletView extends ConsumerStatefulWidget {
  const ImportWalletView({
    super.key,
  });

  @override
  _ImportWalletViewState createState() => _ImportWalletViewState();
}

class _ImportWalletViewState extends ConsumerState<ImportWalletView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _walletKeyController = TextEditingController();
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _walletKeyController.text = "";
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Wallet'),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const InformationCardWidget(
                  message:
                      "Please enter your wallet key you want to import. Make sure to enter the correct key to avoid any issues."),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _walletKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Wallet Key',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 52,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a wallet key';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isSaving = true;
                      });
                    }
                  },
                  onTap: () {
                    // Animate scroll to make space for the keyboard
                    _scrollController.animateTo(
                      0, // Scroll to the top (adjust if needed)
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _isSaving
                  ? const CircularProgressIndicator()
                  : FilledButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() {
                          _isSaving = true;
                        });
                        try {
                          final isExisting = await ref
                              .read(walletListProvider.notifier)
                              .isWalletExisting(_walletKeyController.text.trim());
                          if (isExisting) {
                            if (context.mounted) {
                              informationSnackBarMessage(context, 'Wallet already exists!');
                              Navigator.of(context).pop();
                            }
                          } else {
                            print("wallet does not exits");

                            await ref
                                .read(walletListProvider.notifier)
                                .importExistingWallet(_walletKeyController.text.trim());
                            if (context.mounted) {
                              informationSnackBarMessage(context, 'Wallet imported!');
                              Navigator.of(context).pop();
                            }
                          }
                        } catch (e) {
                          setState(() {
                            _isSaving = false;
                          });
                          if (context.mounted) {
                            informationSnackBarMessage(context,
                                'Error occurred while importing your wallet! The your privake key is invalid!');
                            //Navigator.of(context).pop();
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _walletKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
