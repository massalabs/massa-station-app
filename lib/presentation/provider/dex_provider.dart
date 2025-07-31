// Dart imports:

// Package imports:
import 'package:dusa/dusa.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/domain/usecase/dex_use_case.dart';
import 'package:mug/domain/usecase/dex_use_case_impl.dart';

// Project imports:
import 'package:mug/presentation/state/dex_state.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class DexProvider extends StateNotifier<DexState> {
  DexProvider() : super(DexInitial());
  Future<void> initialLoad(String accountAddress, TokenName token1, TokenName token2);
}

base class DexProviderImpl extends StateNotifier<DexState> implements DexProvider {
  final DexUseCase useCase;

  DexProviderImpl({required this.useCase}) : super(DexInitial());

  @override
  Future<void> initialLoad(String accountAddress, TokenName token1, TokenName token2) async {
    state = DexLoading();

    final result = await useCase.findBestPathFromAmountIn(accountAddress, TokenName.WMAS, TokenName.USDC, 1.0);

    switch (result) {
      case Success(value: final response):
        print('amount in: ${response.amounts}');
        print('route: ${response.router}');
        print('pair: ${response.pair}');
        print('bin steps: ${response.binSteps}');
        final amount1 = response.amounts[0];
        final usdcAmount = bigIntToDecimal(response.amounts[1], getTokenDecimal(TokenName.USDC));

        //get token1/massa balance
        double balance = 0.0;
        final massaBalance = await useCase.getMASBalance(
          accountAddress,
        );
        switch (massaBalance) {
          case Success(value: final value):
            balance = value.finalBalance;
          case Failure():
            balance = 0.0;
        }

        //get token 2 balance
        double balance2 = 0.0;
        final usdcBalance = await useCase.getTokenBalance(accountAddress, TokenName.USDC);
        switch (usdcBalance) {
          case Success(value: final value):
            balance2 = value;
          case Failure():
            balance = 0.0;
        }
        final entity = SwapEntity(
            selectedToken1: "MAS",
            selectedToken2: token2.name,
            token1: TokenName.WMAS,
            token2: TokenName.USDC,
            amountIn: toMAS(amount1),
            amountOut: usdcAmount,
            token1Balance: balance,
            token2Balance: balance2,
            binSteps: response.binSteps,
            tokenPath: response.router,
            exchangeRate: usdcAmount);
        state = DexSuccess(swapEntity: entity);

      case Failure(exception: final exception):
        state = DexFailure(message: 'Something went wrong: $exception!');
    }
  }
}

final dexProvider = StateNotifierProvider<DexProvider, DexState>((ref) {
  print("dex provider initalised...");
  return DexProviderImpl(useCase: ref.watch(dexUseCaseProvider));
});
