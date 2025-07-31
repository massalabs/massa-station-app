import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/constants/constants.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/presentation/provider/wallet_provider.dart';
import 'package:mug/presentation/widget/address_icon.dart';
import 'package:mug/presentation/widget/information_snack_message.dart';
import 'package:mug/utils/string_helpers.dart';

class EditWalletNameView extends ConsumerStatefulWidget {
  final String address;

  const EditWalletNameView({Key? key, required this.address}) : super(key: key);

  @override
  _EditWalletNameViewState createState() => _EditWalletNameViewState();
}

class _EditWalletNameViewState extends ConsumerState<EditWalletNameView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(walletNameProvider.notifier).loadWalletName(widget.address);
      final currentName = ref.read(walletNameProvider);
      _nameController.text = currentName;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletName = ref.watch(walletNameProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Wallet Name'),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: AddressIcon(widget.address),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            shortenString(widget.address, Constants.shortedAddressLength),
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: Constants.fontSize),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.address)).then((result) {
                                if (context.mounted) {
                                  informationSnackBarMessage(context, "Wallet address copied!");
                                }
                              });
                            },
                            icon: const Icon(Icons.copy),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: Text(
                          "Current Name",
                          style: TextStyle(fontSize: Constants.fontSize),
                        ),
                        title: Text(
                          walletName,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: Constants.fontSize),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Wallet Name',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 16,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a wallet name';
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
                        print("Saving wallet name");
                        if (!_formKey.currentState!.validate()) return;
                        setState(() {
                          _isSaving = true;
                        });
                        await ref.read(walletNameProvider.notifier).updateWalletName(
                              widget.address,
                              _nameController.text.trim(),
                            );
                        await ref.read(walletListProvider.notifier).loadWallets();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wallet name saved!')),
                          );
                          Navigator.of(context).pop(true);
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
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
