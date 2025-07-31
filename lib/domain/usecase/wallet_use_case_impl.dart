// Dart imports:

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';

// Project imports:
import 'package:mug/data/model/wallet_model.dart';
import 'package:mug/data/repository/wallet_repository_impl.dart';
import 'package:mug/domain/repository/wallet_repository.dart';
import 'package:mug/domain/usecase/wallet_use_case.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';

import 'package:mug/utils/encryption/aes_encryption.dart';
import 'package:mug/utils/exception_handling.dart';

class WalletUseCaseImpl implements WalletUseCase {
  final WalletRepository repository;
  final LocalStorageService localStorageService;

  WalletUseCaseImpl({
    required this.repository,
    required this.localStorageService,
  });

  @override
  Future<Result<WalletData, Exception>> createWallet() async {
    try {
      final wallet = Wallet();
      final passphrase = await localStorageService.passphrase;
      final account = await wallet.newAccount(AddressType.user, NetworkType.MAINNET);
      final WalletModel walletEntity =
          WalletModel(address: account.address(), encryptedKey: encryptAES(account.privateKey(), passphrase));
      List<WalletModel> wallets;
      final walletString = await localStorageService.getStoredWallets();
      if (walletString.isNotEmpty) {
        wallets = WalletModel.decode(walletString);
        wallets.add(walletEntity);
      } else {
        wallets = [walletEntity];
      }
      await localStorageService.storeWallets(WalletModel.encode(wallets));
      return loadWallets();
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<WalletData, Exception>> loadWallets() async {
    try {
      List<WalletModel> wallets;
      WalletData walletData = WalletData();
      final walletString = await localStorageService.getStoredWallets();
      if (walletString.isNotEmpty) {
        wallets = WalletModel.decode(walletString);
        List<String> walletAddresses = [];
        for (var w in wallets) {
          walletAddresses.add(w.address);
        }

        //print("wallet addresses: $walletAddresses");
        final addressesResult = await repository.getAddresses(walletAddresses);
        final addressesEntity = switch (addressesResult) {
          Success(value: final resp) => resp,
          Failure() => null,
        };
        var i = 0;
        for (var w in wallets) {
          w.addressInformation = addressesEntity![i];
          walletData.finalBalance += addressesEntity[i].finalBalance;
          walletData.rolls += addressesEntity[i].finalRolls;
          i++;
        }
        walletData.wallets = wallets;
        return Success(value: walletData);
      } else {
        return Success(value: walletData);
      }
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<WalletData, Exception>> restoreWallet(String privateKey) async {
    try {
      final wallet = Wallet();
      final passphrase = await localStorageService.passphrase;
      final account = await wallet.addAccountFromSecretKey(privateKey, AddressType.user, NetworkType.MAINNET);
      final WalletModel walletEntity =
          WalletModel(address: account.address(), encryptedKey: encryptAES(account.privateKey(), passphrase));
      //get existing storated wallets
      List<WalletModel> wallets;
      final walletString = await localStorageService.getStoredWallets();
      if (walletString.isNotEmpty) {
        wallets = WalletModel.decode(walletString);
        wallets.add(walletEntity);
      } else {
        wallets = [walletEntity];
      }
      await localStorageService.storeWallets(WalletModel.encode(wallets));
      return loadWallets();
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<WalletData, Exception>> deleteWallet(String address) async {
    try {
      List<WalletModel> wallets;
      WalletData walletData = WalletData();
      final walletString = await localStorageService.getStoredWallets();
      if (walletString.isNotEmpty) {
        wallets = WalletModel.decode(walletString);
        //TODO: check if the wallet has any balance, do not delete it.

        wallets.removeWhere((w) => w.address == address);
        await localStorageService.storeWallets(WalletModel.encode(wallets));
        return loadWallets();
      } else {
        return Success(value: walletData);
      }
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final walletUseCaseProvider = Provider<WalletUseCase>((ref) {
  return WalletUseCaseImpl(
      repository: ref.watch(walletRepositoryProvider), localStorageService: ref.watch(localStorageServiceProvider));
});
