// Dart imports:
import 'dart:developer';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';

// We could also use packages like Freezed to help with the implementation.
@immutable
class Setting {
  final double coinsAmount;
  final double feeAmount;
  final double gasAmount;
  final double slippage;
  final bool darkTheme;
  final bool mainNetwork;
  const Setting({
    required this.coinsAmount,
    required this.feeAmount,
    required this.gasAmount,
    required this.slippage,
    required this.darkTheme,
    required this.mainNetwork,
  });

  Setting copyWith({
    double? coinsAmount,
    double? feeAmount,
    double? gasAmount,
    double? slippage,
    bool? darkTheme,
    bool? mainNetwork,
  }) {
    return Setting(
      coinsAmount: coinsAmount ?? this.coinsAmount,
      feeAmount: feeAmount ?? this.feeAmount,
      gasAmount: gasAmount ?? this.gasAmount,
      slippage: slippage ?? this.slippage,
      darkTheme: darkTheme ?? this.darkTheme,
      mainNetwork: mainNetwork ?? this.mainNetwork,
    );
  }
}

class SettingProvider extends StateNotifier<Setting> {
  final LocalStorageService localStorageService;

  SettingProvider({
    required this.localStorageService,
  }) : super(const Setting(
            coinsAmount: 0.01, feeAmount: 0.01, gasAmount: 0.01, slippage: 0.5, darkTheme: true, mainNetwork: true)) {
    loadSetting();
  }

  Future<void> loadSetting() async {
    var coinsAmount = localStorageService.minimumFee;
    var darkTheme = localStorageService.isThemeDark;
    var feeAmount = localStorageService.minimumFee;
    var gasAmount = localStorageService.minimumGassFee;
    var slippage = localStorageService.slippage;
    var networkType = localStorageService.isMainnet;
    state = Setting(
        coinsAmount: coinsAmount,
        feeAmount: feeAmount,
        gasAmount: gasAmount,
        slippage: slippage,
        darkTheme: darkTheme,
        mainNetwork: networkType);
    _debug();
  }

  Future<double> changeTxFee({required double feeAmount}) async {
    final fee = await localStorageService.setMinimumFee(feeAmount);
    state = state.copyWith(feeAmount: fee);
    _debug();
    return fee;
  }

  Future<double> changeGasFee({required double gasFeeAmount}) async {
    final fee = await localStorageService.setMinimumGassFee(gasFeeAmount);
    state = state.copyWith(gasAmount: fee);

    print("fee: $fee");
    _debug();
    return fee;
  }

  Future<void> changeSlippage({required double slippage}) async {
    state = state.copyWith(slippage: slippage);
    await localStorageService.setSlipage(slippage);
    _debug();
  }

  Future<void> changeTheme({required bool isDarkTheme}) async {
    state = state.copyWith(darkTheme: isDarkTheme);
    await localStorageService.setIsThemeDark(isDarkTheme);
    _debug();
  }

  Future<void> changeNetwork({required bool isMainNet}) async {
    state = state.copyWith(mainNetwork: isMainNet);
    await localStorageService.setNetworkType(isMainNet);
    _debug();
  }

  void _debug() {
    log('Setting: coins = ${state.coinsAmount}, fee = ${state.feeAmount}, gas = ${state.gasAmount}, isDark theme = ${state.darkTheme}, isMainNetwor = ${state.mainNetwork}');
  }
}

final settingProvider = StateNotifierProvider<SettingProvider, Setting>((ref) {
  return SettingProvider(localStorageService: ref.watch(localStorageServiceProvider));
});
