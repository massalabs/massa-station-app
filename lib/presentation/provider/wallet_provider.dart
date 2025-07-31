// Dart imports:
// Package imports:
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/data/model/wallet_model.dart';
import 'package:mug/domain/entity/address_entity.dart';

// Project imports:
import 'package:mug/domain/usecase/explorer_use_case.dart';
import 'package:mug/domain/usecase/explorer_use_case_impl.dart';
import 'package:mug/presentation/state/wallet_state.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class WalletProvider extends StateNotifier<WalletState> {
  WalletProvider() : super(WalletLoading());
  Future<void> getWalletInformation(String address, bool getTokenBalance);
  bool setDefaultAccount(String address);
  Future<AddressEntity?> getDefaultWalletInformation(bool getTokenBalance);
  Future<bool> isAccountDefault(String address);
  Future<String?> getWalletKey(String address);
  Future<void> renameWallet(String address, String name);
  Future<String?> getWalletName(String address);
  String computeTimestampAge(int timestampMillis);
}

base class WalletProviderImpl extends StateNotifier<WalletState> implements WalletProvider {
  final ExplorerUseCase explorerUseCase;
  final LocalStorageService localStorageService;

  WalletProviderImpl({
    required this.explorerUseCase,
    required this.localStorageService,
  }) : super(WalletLoading());

  @override
  Future<void> getWalletInformation(String address, bool getTokenBalance) async {
    state = WalletLoading();
    final result = await explorerUseCase.getAddress(address, getTokenBalance);
    switch (result) {
      case Success(value: final response):
        state = WalletSuccess(addressEntity: response);
      case Failure(exception: final exception):
        state = WalletFailure(message: 'Something went wrong: $exception');
    }
  }

  @override
  Future<AddressEntity?> getDefaultWalletInformation(bool getTokenBalance) async {
    final defaultAddress = await localStorageService.getDefaultWallet();
    final result = await explorerUseCase.getAddress(defaultAddress!, getTokenBalance);
    switch (result) {
      case Success(value: final response):
        return response;
      case Failure(exception: final exception):
        if (kDebugMode) {
          print("error getting default wallet info: $exception");
        }
        return null;
    }
  }

  @override
  bool setDefaultAccount(String address) {
    localStorageService.setDefaultWallet(address);
    return true;
  }

  @override
  Future<bool> isAccountDefault(String address) async {
    final defaultAddress = await localStorageService.getDefaultWallet();
    if (address == defaultAddress) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<String?> getWalletKey(String address) async {
    return await localStorageService.getWalletKey(address);
  }

  @override
  Future<void> renameWallet(String address, String name) async {
    final walletString = await localStorageService.getStoredWallets();
    final wallets = WalletModel.decode(walletString);
    for (int i = 0; i < wallets.length; i++) {
      if (wallets[i].address == address) {
        wallets[i] = wallets[i].copyWith(name: name);
        break;
      }
    }
    await localStorageService.storeWallets(WalletModel.encode(wallets));
  }

  @override
  Future<String?> getWalletName(String address) async {
    final walletString = await localStorageService.getStoredWallets();
    final wallets = WalletModel.decode(walletString);
    for (int i = 0; i < wallets.length; i++) {
      if (wallets[i].address == address) {
        return wallets[i].name;
      }
    }
    return address.substring(address.length - 4);
  }

  String computeTimestampAge(int timestampMillis) {
    // Convert input timestamp from milliseconds to DateTime
    DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis, isUtc: true);

    // Get the current time in UTC
    DateTime now = DateTime.now().toUtc();

    // Calculate the difference as a Duration
    Duration difference = now.difference(timestamp);

    if (difference.inSeconds < 86400) {
      // Less than a day, format as hh:mm:ss
      int hours = difference.inHours;
      int minutes = difference.inMinutes % 60;
      int seconds = difference.inSeconds % 60;
      return '${hours.toString().padLeft(2, '0')}h '
          '${minutes.toString().padLeft(2, '0')}m '
          '${seconds.toString().padLeft(2, '0')}s';
    } else if (difference.inDays < 30) {
      // Less than a month, format as d:hh:mm
      int days = difference.inDays;
      int hours = difference.inHours % 24;
      int minutes = difference.inMinutes % 60;
      return '${days}d ${hours.toString().padLeft(2, '0')}h '
          '${minutes.toString().padLeft(2, '0')}m';
    } else if (difference.inDays < 365) {
      // Less than a year, format as m:d:h
      int months = difference.inDays ~/ 30; // Approximate months
      int days = difference.inDays % 30;
      int hours = difference.inHours % 24;
      return '${months}m ${days}d ${hours}h';
    } else {
      // Greater than or equal to a year, show years:months:days
      int years = difference.inDays ~/ 365;
      int months = (difference.inDays % 365) ~/ 30; // Approximate months
      int days = (difference.inDays % 365) % 30;
      return '${years}y ${months}m ${days}d';
    }
  }
}

final walletProvider = StateNotifierProvider<WalletProvider, WalletState>((ref) {
  return WalletProviderImpl(
      explorerUseCase: ref.watch(explorerUseCaseProvider), localStorageService: ref.watch(localStorageServiceProvider));
});

// Notifier to manage the wallet name state
class WalletNameNotifier extends StateNotifier<String> {
  final LocalStorageService localStorageService;

  WalletNameNotifier({required this.localStorageService}) : super(''); // Initialize with an empty string

  Future<void> loadWalletName(String address) async {
    final walletString = await localStorageService.getStoredWallets();
    final wallets = WalletModel.decode(walletString);
    for (int i = 0; i < wallets.length; i++) {
      if (wallets[i].address == address) {
        state = wallets[i].name ?? address.substring(address.length - 4);
        return;
      }
    }
    state = address.substring(address.length - 4); // Fallback to last 4 characters of the address
  }

  Future<void> updateWalletName(String address, String newName) async {
    //save wallet to the database first
    final walletString = await localStorageService.getStoredWallets();
    final wallets = WalletModel.decode(walletString);
    for (int i = 0; i < wallets.length; i++) {
      if (wallets[i].address == address) {
        wallets[i] = wallets[i].copyWith(name: newName);
      }
    }
    await localStorageService.storeWallets(WalletModel.encode(wallets));
    state = newName;
  }
}

final walletNameProvider = StateNotifierProvider<WalletNameNotifier, String>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return WalletNameNotifier(localStorageService: localStorageService);
});
