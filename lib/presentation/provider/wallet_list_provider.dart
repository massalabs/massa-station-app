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
import 'package:mug/service/session_manager.dart';
import 'package:mug/utils/encryption/pbkdf2_encryption.dart';
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

    // Get master key from RAM cache
    final masterKey = SessionManager().masterKey;
    if (masterKey == null) {
      throw Exception('Session expired - please login again');
    }

    final wallet = Wallet();
    final account = await wallet.newAccount(AddressType.user, NetworkType.MAINNET);

    final walletEntity = WalletModel(
        address: account.address(),
        encryptedKey: encryptWithMasterKey(account.privateKey(), masterKey),
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
      // Get master key from RAM cache
      final masterKey = SessionManager().masterKey;
      if (masterKey == null) {
        print('ERROR: Master key is null during wallet import');
        throw Exception('Session expired - please login again');
      }

      final wallet = Wallet();
      final account = await wallet.addAccountFromSecretKey(privateKey, AddressType.user, NetworkType.MAINNET);
      print('Import: Created account with address ${account.address()}');

      // Check if the account already exists
      try {
        final existingWalletKey = await localStorageService.getWalletKey(account.address());
        if (existingWalletKey != null && existingWalletKey != "") {
          print('Import: Wallet already exists, not importing');
          state = AsyncData(await _loadWallets());
          return;
        }
      } catch (e) {
        // Wallet doesn't exist, continue with import
        print('Import: Wallet check failed (expected if new): $e');
      }

      final walletEntity = WalletModel(
        address: account.address(),
        encryptedKey: encryptWithMasterKey(account.privateKey(), masterKey),
      );

      // Get existing stored wallets
      List<WalletModel> wallets;
      final walletString = await localStorageService.getStoredWallets();
      if (walletString.isNotEmpty) {
        wallets = WalletModel.decode(walletString);
        wallets.add(walletEntity);
        print('Import: Adding to existing ${wallets.length - 1} wallets');
        await localStorageService.storeWallets(WalletModel.encode(wallets));
      } else {
        wallets = [walletEntity];
        print('Import: Creating first wallet');
        await localStorageService.storeWallets(WalletModel.encode(wallets));
        await localStorageService.setDefaultWallet(account.address());
        ref.invalidate(accountProvider);
        ref.invalidate(smartContractServiceProvider);
      }
      print('Import: Wallet saved successfully');
      state = AsyncData(await _loadWallets()); //Re-fetch the wallets to update the state
    } catch (e, stack) {
      // Handle errors and update state
      print('Import ERROR: $e');
      print('Import STACK: $stack');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Creates the initial wallet
  Future<bool> isWalletExisting(String privateKey) async {
    try {
      final wallet = Wallet();
      final account = await wallet.addAccountFromSecretKey(privateKey, AddressType.user, NetworkType.MAINNET);
      final existingWalletKey = await localStorageService.getWalletKey(account.address());
      if (existingWalletKey != null && existingWalletKey != "") {
        return true;
      }
    } catch (e) {
      // Wallet doesn't exist or session expired
      return false;
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
