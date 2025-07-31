import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/presentation/view/wallet/wallet_view.dart';

class WalletSelectionNotifier extends StateNotifier<WalletViewArg?> {
  WalletSelectionNotifier() : super(null);

  void selectWallet(WalletViewArg wallet) {
    state = wallet;
  }

  void clearSelection() {
    state = null;
  }
}

final walletSelectionProvider = StateNotifierProvider<WalletSelectionNotifier, WalletViewArg?>((ref) {
  return WalletSelectionNotifier();
});