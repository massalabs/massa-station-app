// Dart imports:

// Package imports:
import 'package:dusa/dusa.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/constants/asset_names.dart';
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/domain/usecase/dex_use_case.dart';
import 'package:mug/domain/usecase/dex_use_case_impl.dart';

// Project imports:
import 'package:mug/presentation/state/swap_state.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class SwapProvider extends StateNotifier<SwapState> {
  SwapProvider(super._state);
  Future<void> initialLoad(String accountAddress);
  void selectDropdown1(String? newValue);
  void selectDropdown2(String? newValue);
  void updateValues(double? value1, double? value2);
  void flipTokens();
  double computeExchangeResult(double value);
  String getOtherTokenName();
  void swap(double? value1, double? value2);
  Future<void> updateSwapRate();
  void resetNotification();
}

final tokenItems = {
  'WETH': DropdownItem(name: "WETH", iconPath: AssetName.eth, token: TokenName.WETH),
  'MAS': DropdownItem(name: "MAS", iconPath: AssetName.mas, token: TokenName.WMAS),
  'WMAS': DropdownItem(name: "WMAS", iconPath: AssetName.wmas, token: TokenName.WMAS),
  'USDC': DropdownItem(name: "USDC", iconPath: AssetName.usdc, token: TokenName.USDC),
};

base class SwapProviderImpl extends StateNotifier<SwapState> implements SwapProvider {
  final DexUseCase useCase;
  SwapProviderImpl({required this.useCase})
      : super(SwapState(
          selectedDropdown1: "MAS",
          selectedDropdown2: "USDC",
          balance1: 0.0,
          balance2: 0.0,
          value1: 0.0,
          value2: 0.0,
          exchangeRate: 0.5,
          allItems: tokenItems,
          status: SwapStatus.loading,
          showNotification: false,
        ));

  @override
  Future<void> initialLoad(String accountAddress) async {
    state = SwapState(
      accountAddress: accountAddress,
      selectedDropdown1: "MAS",
      selectedDropdown2: "USDC",
      allItems: tokenItems,
      showNotification: false,
    );
    await updateSwapRate();
  }

  @override
  Future<void> updateSwapRate() async {
    state = state.copyWith(status: SwapStatus.loading);
    await _getTokenBalances(
      state.accountAddress!,
    );

    if ((state.selectedDropdown1 == 'MAS' && state.selectedDropdown2 == 'WMAS') ||
        (state.selectedDropdown1 == 'WMAS' && state.selectedDropdown2 == 'MAS')) {
      state = state.copyWith(exchangeRate: 1.0, status: SwapStatus.success);
      return;
    }

    final token1 = tokenItems[state.selectedDropdown1]!.token;
    final token2 = tokenItems[state.selectedDropdown2]!.token;
    if (state.selectedDropdown2 != 'MAS') {
      final result = await useCase.findBestPathFromAmountIn(state.accountAddress!, TokenName.WMAS, token2, 1.0);
      switch (result) {
        case Success(value: final response):
          final entity = SwapEntity(
              selectedToken1: token1.name,
              selectedToken2: token2.name,
              token1: token1,
              token2: token2,
              amountIn: bigIntToDecimal(response.amounts[0], getTokenDecimal(token1)),
              amountOut: bigIntToDecimal(response.amounts[1], getTokenDecimal(token2)),
              binSteps: response.binSteps,
              tokenPath: response.router,
              exchangeRate: bigIntToDecimal(response.amounts[1], getTokenDecimal(token2)));
          state = state.copyWith(
            swapEntity: entity,
            exchangeRate: entity.exchangeRate,
            status: SwapStatus.swap,
          );
          break;
        case Failure():
          state = state.copyWith(status: SwapStatus.error);
      }
    } else {
      final result = await useCase.findBestPathFromAmountOut(state.accountAddress!, TokenName.WMAS, token1, 1.0);
      switch (result) {
        case Success(value: final response):
          final entity = SwapEntity(
              selectedToken1: token1.name,
              selectedToken2: token2.name,
              token1: token1,
              token2: token2,
              amountIn: bigIntToDecimal(response.amounts[0], getTokenDecimal(token1)),
              amountOut: bigIntToDecimal(response.amounts[1], getTokenDecimal(token2)),
              binSteps: response.binSteps,
              tokenPath: response.router,
              exchangeRate: bigIntToDecimal(response.amounts[1], getTokenDecimal(token1)));
          state = state.copyWith(
            swapEntity: entity,
            exchangeRate: entity.exchangeRate,
            status: SwapStatus.swap,
          );
          break;
        case Failure():
          state = state.copyWith(status: SwapStatus.error);
      }
    }
  }

  Future<void> _getTokenBalances(String accountAddress) async {
    //get token 1 balances
    double balance1 = 0.0;
    if (state.selectedDropdown1 != "MAS") {
      final token1 = tokenItems[state.selectedDropdown1]!.token;
      balance1 = await _getTokenBalance(accountAddress, token1);
    } else {
      balance1 = await _getMassaBalance(
        accountAddress,
      );
    }

    //get token 2 balances
    double balance2 = 0.0;
    if (state.selectedDropdown2 != "MAS") {
      final token2 = tokenItems[state.selectedDropdown2]!.token;
      balance2 = await _getTokenBalance(accountAddress, token2);
    } else {
      balance2 = await _getMassaBalance(
        accountAddress,
      );
    }

    state = state.copyWith(
      balance1: balance1,
      balance2: balance2,
    );
  }

  Future<double> _getMassaBalance(String accountAddress) async {
    double balance = 0.0;
    final massaBalance = await useCase.getMASBalance(
      accountAddress,
    );
    switch (massaBalance) {
      case Success(value: final value):
        balance = value.finalBalance;
        break;
      case Failure():
        balance = 0.0;
    }
    return balance;
  }

  Future<double> _getTokenBalance(String accountAddress, TokenName token) async {
    double balance = 0.0;
    final tokenBalance = await useCase.getTokenBalance(accountAddress, token);
    switch (tokenBalance) {
      case Success(value: final value):
        balance = value;
        if (kDebugMode) {
          print('DEBUG: Final balance for $token: $balance');
        }
        break;
      case Failure():
        balance = 0.0;
        if (kDebugMode) {
          print('DEBUG: Failed to get balance for $token, setting to 0.0');
        }
    }
    return balance;
  }

// Method to update the selected item in Dropdown 1
  @override
  Future<void> selectDropdown1(String? newValue) async {
    if (newValue == state.selectedDropdown1) {
      return; //prevent updating the state if the value has not changed
    }
    if (newValue != 'MAS') {
      state = state.copyWith(selectedDropdown1: newValue, selectedDropdown2: "MAS");
    } else if (newValue == 'MAS' && state.selectedDropdown2 == 'MAS') {
      state = state.copyWith(selectedDropdown1: newValue, selectedDropdown2: "WMAS");
    }
    await updateSwapRate();
  }

  // Method to update the selected item in Dropdown 2
  @override
  Future<void> selectDropdown2(String? newValue) async {
    if (newValue == state.selectedDropdown2) {
      return; //prevent updating the state if the value has not changed
    }
    if (newValue != 'MAS') {
      state = state.copyWith(selectedDropdown1: "MAS", selectedDropdown2: newValue);
    } else if (newValue == 'MAS' && state.selectedDropdown1 == 'MAS') {
      state = state.copyWith(selectedDropdown1: "WMAS", selectedDropdown2: newValue);
    }
    await updateSwapRate();
  }

  @override
  Future<void> swap(double? value1, double? value2) async {
    state = state.copyWith(status: SwapStatus.loading);
    final token1 = tokenItems[state.selectedDropdown1]!.token;
    final token2 = tokenItems[state.selectedDropdown2]!.token;
    final entity = state.swapEntity!.copyWith(
      selectedToken1: state.selectedDropdown1,
      selectedToken2: state.selectedDropdown2,
      amountIn: value1,
      amountOut: value2,
      token1: token1,
      token2: token2,
    );
    final result = await useCase.swapToken(state.accountAddress!, entity);
    switch (result) {
      case Success(value: final value):
        state = state.copyWith(status: SwapStatus.success, showNotification: true, notificationMessage: value.$1);
        break;
      case Failure():
    }
  }

  @override
  void updateValues(double? value1, double? value2) {
    state = state.copyWith(value1: value1 ?? state.value1, value2: value2 ?? state.value2);
  }

  @override
  double computeExchangeResult(double value) {
    if (state.selectedDropdown1 == "MAS") {
      return state.exchangeRate! * value;
    }
    return value / state.exchangeRate!;
  }

  @override
  String getOtherTokenName() {
    if (state.selectedDropdown1 != "MAS") {
      return state.selectedDropdown1!;
    }
    return state.selectedDropdown2!;
  }

  @override
  void flipTokens() {
    state = state.copyWith(
      selectedDropdown1: state.selectedDropdown2,
      selectedDropdown2: state.selectedDropdown1,
      balance1: state.balance2,
      balance2: state.balance1,
    );
  }

  @override
  void resetNotification() {
    state = state.copyWith(showNotification: false, notificationMessage: "");
  }
}

final swapProvider = StateNotifierProvider<SwapProvider, SwapState>((ref) {
  return SwapProviderImpl(useCase: ref.watch(dexUseCaseProvider));
});
