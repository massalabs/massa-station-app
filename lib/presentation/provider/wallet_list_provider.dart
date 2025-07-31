// Dart imports:

// Package imports:
import 'dart:ffi';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/data/model/wallet_model.dart';

// Project imports:
import 'package:mug/domain/usecase/wallet_use_case.dart';
import 'package:mug/domain/usecase/wallet_use_case_impl.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/utils/encryption/aes_encryption.dart';
import 'package:mug/utils/exception_handling.dart';

class WalletListNotifier extends AsyncNotifier<WalletData?> {
  late final LocalStorageService localStorageService;
  late final WalletUseCase walletUseCase;

  @override
  Future<WalletData?> build() async {
    localStorageService = ref.read(localStorageServiceProvider);
    walletUseCase = ref.read(walletUseCaseProvider);

    final wallets = await _loadWallets();
    return wallets;
  }

  Future<void> createNewWallet() async {
    state = const AsyncValue.loading(); // Set state to loading

    final wallet = Wallet();
    final passphrase = await localStorageService.passphrase;
    final account = await wallet.newAccount(AddressType.user, NetworkType.MAINNET);

    final walletEntity = WalletModel(
        address: account.address(),
        encryptedKey: encryptAES(account.privateKey(), passphrase),
        name: account.address().substring(account.address().length - 4));

    List<WalletModel> wallets;
    final walletString = await localStorageService.getStoredWallets();
    if (walletString.isNotEmpty) {
      wallets = WalletModel.decode(walletString);
      wallets.add(walletEntity);
      await localStorageService.storeWallets(WalletModel.encode(wallets));
    } else {
      wallets = [walletEntity];
      await localStorageService.storeWallets(WalletModel.encode(wallets));
      await localStorageService.setDefaultWallet(account.address());
      ref.invalidate(accountProvider);
      ref.invalidate(smartContractServiceProvider);
    }
    state = AsyncData(await _loadWallets()); //Re-fetch the wallets to update the state
  }

  /// Creates the initial wallet
  Future<void> importExistingWallet(String privateKey) async {
    state = const AsyncValue.loading(); // Set state to loading
    try {
      final wallet = Wallet();
      final passphrase = await localStorageService.passphrase;

      final account = await wallet.addAccountFromSecretKey(privateKey, AddressType.user, NetworkType.MAINNET);

      // Check if the account already exists
      final existingWalletKey = await localStorageService.getWalletKey(account.address());
      if (existingWalletKey != "") {
        state = AsyncData(await _loadWallets());
        return;
      }

      final walletEntity = WalletModel(
        address: account.address(),
        encryptedKey: encryptAES(account.privateKey(), passphrase),
      );

      // Get existing stored wallets
      List<WalletModel> wallets;
      final walletString = await localStorageService.getStoredWallets();
      if (walletString.isNotEmpty) {
        wallets = WalletModel.decode(walletString);
        wallets.add(walletEntity);
        await localStorageService.storeWallets(WalletModel.encode(wallets));
      } else {
        wallets = [walletEntity];
        await localStorageService.storeWallets(WalletModel.encode(wallets));
        await localStorageService.setDefaultWallet(account.address());
        ref.invalidate(accountProvider);
        ref.invalidate(smartContractServiceProvider);
      }
      state = AsyncData(await _loadWallets()); //Re-fetch the wallets to update the state
    } catch (e, stack) {
      // Handle errors and update state
      state = AsyncValue.error(e, stack);
    }
  }

  /// Creates the initial wallet
  Future<bool> isWalletExisting(String privateKey) async {
    final wallet = Wallet();
    final account = await wallet.addAccountFromSecretKey(privateKey, AddressType.user, NetworkType.MAINNET);
    final existingWalletKey = await localStorageService.getWalletKey(account.address());
    if (existingWalletKey != "") {
      return true;
    }
    return false;
  }

  Future<void> loadWallets() async {
    //state = const AsyncValue.loading(); // Set state to loading
    try {
      state = AsyncData(await _loadWallets()); //Re-fetch the wallets to update the state
    } catch (e, stack) {
      // Handle errors and update state
      state = AsyncValue.error(e, stack);
    }
  }

  Future<WalletData?> _loadWallets() async {
    final result = await walletUseCase.loadWallets();
    switch (result) {
      case Success(value: final response):
        return response;
      case Failure(exception: final exception):
        return null;
    }
  }
}

final walletListProvider = AsyncNotifierProvider<WalletListNotifier, WalletData?>(() {
  return WalletListNotifier();
});
