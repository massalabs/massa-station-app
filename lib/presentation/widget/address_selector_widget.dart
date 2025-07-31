import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/utils/string_helpers.dart';

class AddressSelectorWidget extends ConsumerStatefulWidget {
  final String currentAddress;
  final TextEditingController addressController;

  const AddressSelectorWidget({
    required this.currentAddress,
    required this.addressController,
    super.key,
  });

  @override
  ConsumerState<AddressSelectorWidget> createState() => _AddressSelectorWidgetState();
}

class _AddressSelectorWidgetState extends ConsumerState<AddressSelectorWidget> {
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    widget.addressController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.addressController.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    if (_selectedAddress != null && widget.addressController.text != _selectedAddress) {
      setState(() {
        _selectedAddress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsyncValue = ref.watch(walletListProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title for paste area
          const Text(
            "Please paste the recipient address here:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Visible container for pasting address
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextFormField(
              enabled: true,
              maxLines: 3,
              controller: widget.addressController,
              onChanged: (value) {
                // The listener will handle resetting the dropdown
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1, color: Colors.blue, height: 24),
          const Text(
            "Or send to one of my addresses:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          walletAsyncValue.when(
            data: (walletData) {
              if (walletData == null || walletData.wallets.isEmpty) {
                return const Text("No available addresses to select.");
              }
              final wallets = walletData.wallets.where((wallet) => wallet.address != widget.currentAddress).toList();

              return DropdownButtonFormField<String>(
                value: _selectedAddress,
                items: wallets
                    .map(
                      (wallet) => DropdownMenuItem(
                        value: wallet.address,
                        child: Text(shortenString(wallet.address, 26)),
                      ),
                    )
                    .toList(),
                onChanged: (selectedAddress) {
                  setState(() {
                    _selectedAddress = selectedAddress;
                    if (selectedAddress != null) {
                      widget.addressController.text = selectedAddress;
                    }
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  hintText: 'Select the recipient address',
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Error loading addresses: $error'),
          ),
        ],
      ),
    );
  }
}
