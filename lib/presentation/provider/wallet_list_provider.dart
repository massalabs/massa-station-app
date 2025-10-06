// Dart imports:

// Package imports:
import 'dart:ffi';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/data/model/wallet_model.dart';
import 'package:mug/domain/entity/address_entity.dart';

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
    final startTime = DateTime.now();
    print('⏱️ WalletListNotifier.build(): START at ${startTime.millisecondsSinceEpoch}');

    localStorageService = ref.read(localStorageServiceProvider);
    walletUseCase = ref.read(walletUseCaseProvider);

    print('🟢 WalletListNotifier.build(): Loading wallets');
    try {
      // Load offline data first to show immediately
      final offlineStartTime = DateTime.now();
      final offlineData = await _loadWalletsOffline();
      final offlineEndTime = DateTime.now();
      final offlineDuration = offlineEndTime.difference(offlineStartTime).inMilliseconds;
      print('⏱️ Offline data loaded in ${offlineDuration}ms');

      // Start API call to update in background (but don't wait for it here)
      final apiStartTime = DateTime.now();
      print('⏱️ Starting background API update');

      // Try to get API data with short timeout
      _loadWallets().then((wallets) {
        final apiEndTime = DateTime.now();
        final apiDuration = apiEndTime.difference(apiStartTime).inMilliseconds;
        if (wallets != null) {
          print('🟢 Background API update completed in ${apiDuration}ms, updating state');
          // Update state with fresh API data
          state = AsyncData(wallets);
        } else {
          print('⚠️ Background API update failed after ${apiDuration}ms');
        }
      }).catchError((e) {
        print('❌ Background API update error: $e');
      });

      // Return offline data immediately
      final totalDuration = offlineEndTime.difference(startTime).inMilliseconds;
      print('✅ Returning offline data, total ${totalDuration}ms');
      return offlineData;
    } catch (e, s) {
      print('❌ WalletListNotifier.build() ERROR: $e');
      print('❌ Stack: $s');
      final offlineData = await _loadWalletsOffline();
      final endTime = DateTime.now();
      final totalDuration = endTime.difference(startTime).inMilliseconds;
      print('⏱️ Total time (with error): ${totalDuration}ms');
      return offlineData;
    }
  }

  Future<void> createNewWallet() async {
    state = const AsyncValue.loading(); // Set state to loading

    try {
      print('🟢 createNewWallet: Starting wallet creation');

      // Get master key from RAM cache
      final masterKey = SessionManager().masterKey;
      if (masterKey == null) {
        throw Exception('Session expired - please login again');
      }

      print('🟢 createNewWallet: Generating new account');
      final wallet = Wallet();
      final account = await wallet.newAccount(AddressType.user, NetworkType.MAINNET);

      final walletEntity = WalletModel(
          address: account.address(),
          encryptedKey: encryptWithMasterKey(account.privateKey(), masterKey),
          name: account.address().substring(account.address().length - 4));

      print('🟢 createNewWallet: Storing wallet locally');
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

      print('🟢 createNewWallet: Loading offline data immediately');
      // Load offline data first to show immediately
      final offlineData = await _loadWalletsOffline();
      print('🟡 createNewWallet: Offline data loaded with ${offlineData.wallets.length} wallets');
      state = AsyncData(offlineData);
      print('✅ createNewWallet: State updated successfully');

      // Start background API update (don't wait for it)
      print('🟢 createNewWallet: Starting background API update');
      _loadWallets().then((loadedData) {
        if (loadedData != null) {
          print('🟢 createNewWallet: Background API update successful, refreshing state');
          state = AsyncData(loadedData);
        } else {
          print('⚠️ createNewWallet: Background API update failed');
        }
      }).catchError((e) {
        print('❌ createNewWallet: Background API update error: $e');
      });
    } catch (e, stack) {
      print('❌ createNewWallet ERROR: $e');
      print('❌ createNewWallet STACK: $stack');
      state = AsyncValue.error(e, stack);
    }
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
          final loadedData = await _loadWallets();
          state = AsyncData(loadedData ?? await _loadWalletsOffline());
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

      // Try to load wallets with API data, but fallback to local data if offline
      final loadedData = await _loadWallets();
      if (loadedData != null) {
        state = AsyncData(loadedData);
      } else {
        state = AsyncData(await _loadWalletsOffline());
      }
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
      // Load offline data immediately to show updated list right away
      print('🔄 loadWallets: Loading offline data first');
      final offlineData = await _loadWalletsOffline();
      state = AsyncData(offlineData);
      print('🔄 loadWallets: Offline data displayed, starting background API update');

      // Start background API update (don't wait for it)
      _loadWallets().then((loadedData) {
        if (loadedData != null) {
          print('🔄 loadWallets: Background API update successful');
          state = AsyncData(loadedData);
        } else {
          print('🔄 loadWallets: Background API update failed');
        }
      }).catchError((e) {
        print('❌ loadWallets: Background API update error: $e');
      });
    } catch (e, stack) {
      // Handle errors and update state
      print('❌ loadWallets ERROR: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<WalletData?> _loadWallets() async {
    final methodStart = DateTime.now();
    print('⏱️ _loadWallets: Method START');
    try {
      // Add timeout to prevent hanging when offline
      final useCaseStart = DateTime.now();
      final result = await walletUseCase.loadWallets().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          final timeoutTime = DateTime.now();
          final elapsed = timeoutTime.difference(useCaseStart).inMilliseconds;
          print('⏱️ _loadWallets: Timeout after ${elapsed}ms (5s limit)');
          return Failure(exception: Exception('Network timeout'));
        },
      );
      final useCaseEnd = DateTime.now();
      final useCaseDuration = useCaseEnd.difference(useCaseStart).inMilliseconds;
      print('⏱️ _loadWallets: walletUseCase.loadWallets() took ${useCaseDuration}ms');

      switch (result) {
        case Success(value: final response):
          final totalDuration = DateTime.now().difference(methodStart).inMilliseconds;
          print('⏱️ _loadWallets: SUCCESS - total ${totalDuration}ms');
          return response;
        case Failure(exception: final exception):
          final totalDuration = DateTime.now().difference(methodStart).inMilliseconds;
          print('⚠️ _loadWallets: Failed with $exception after ${totalDuration}ms');
          return null;
      }
    } catch (e) {
      final totalDuration = DateTime.now().difference(methodStart).inMilliseconds;
      print('❌ _loadWallets: Exception $e after ${totalDuration}ms');
      return null;
    }
  }

  /// Load wallets from local storage only (offline mode)
  Future<WalletData> _loadWalletsOffline() async {
    final startTime = DateTime.now();
    print('⏱️ _loadWalletsOffline: START');

    WalletData walletData = WalletData();

    final readStart = DateTime.now();
    final walletString = await localStorageService.getStoredWallets();
    final readDuration = DateTime.now().difference(readStart).inMilliseconds;
    print('⏱️ _loadWalletsOffline: getStoredWallets() took ${readDuration}ms');

    if (walletString.isNotEmpty) {
      final decodeStart = DateTime.now();
      final wallets = WalletModel.decode(walletString);
      final decodeDuration = DateTime.now().difference(decodeStart).inMilliseconds;
      print('⏱️ _loadWalletsOffline: decode took ${decodeDuration}ms for ${wallets.length} wallets');

      // Create placeholder AddressEntity for each wallet (offline mode)
      final entityStart = DateTime.now();
      for (var wallet in wallets) {
        wallet.addressInformation = AddressEntity(
          address: wallet.address,
          thread: 0,
          finalBalance: -1, // -1 indicates loading/offline
          candidateBalance: -1,
          finalRolls: -1,
          candidateRolls: -1,
          activeRoles: -1,
          createdBlocks: -1,
          createdEndorsements: -1,
          transactionHistory: null,
          tokenBalances: null,
        );
      }
      final entityDuration = DateTime.now().difference(entityStart).inMilliseconds;
      print('⏱️ _loadWalletsOffline: creating entities took ${entityDuration}ms');

      walletData.wallets = wallets;
      walletData.finalBalance = 0; // Will show as loading in UI
      walletData.rolls = 0;
    }

    final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
    print('⏱️ _loadWalletsOffline: TOTAL ${totalDuration}ms');
    return walletData;
  }
}

final walletListProvider = AsyncNotifierProvider<WalletListNotifier, WalletData?>(() {
  return WalletListNotifier();
});
