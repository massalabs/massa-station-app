// Package imports:
import 'package:dusa/dusa.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/data/repository/dex_repository_impl.dart';
import 'package:mug/domain/entity/entity.dart';

// Project imports:
import 'package:mug/domain/repository/dex_repository.dart';
import 'package:mug/domain/usecase/dex_use_case.dart';
import 'package:mug/utils/exception_handling.dart';

class DexUseCaseImpl implements DexUseCase {
  final DexRepository repository;

  DexUseCaseImpl({
    required this.repository,
  });

  @override
  Future<Result<QuoterEntity, Exception>> findBestPathFromAmountIn(
      String accountAddress, TokenName token1, TokenName token2, double amount) async {
    try {
      return await repository.findBestPathFromAmountIn(accountAddress, token1, token2, amount);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<QuoterEntity, Exception>> findBestPathFromAmountOut(
      String accountAddress, TokenName token1, TokenName token2, double amount) async {
    try {
      return await repository.findBestPathFromAmountOut(accountAddress, token1, token2, amount);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<AddressEntity, Exception>> getMASBalance(
    String accountAddress,
  ) async {
    try {
      return await repository.getMASBalance(
        accountAddress,
      );
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<double, Exception>> getTokenBalance(accountAddress, TokenName tokenType) async {
    try {
      final result = await repository.getTokenBalance(accountAddress, tokenType);
      return switch (result) {
        Success(value: final value) => () {
          if (kDebugMode) {
            print('DEBUG: Token $tokenType decimals: ${getTokenDecimal(tokenType)}');
            print('DEBUG: Converting BigInt $value to decimal');
          }
          return Success(value: bigIntToDecimal(value, getTokenDecimal(tokenType)));
        }(),
        Failure(exception: final exception) => Failure(exception: Exception("unable to get token balance: $exception"))
      };
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<(String, bool), Exception>> swapToken(String accountAddress, SwapEntity data) async {
    try {
      return await repository.swapToken(accountAddress, data);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final dexUseCaseProvider = Provider<DexUseCase>((ref) {
  return DexUseCaseImpl(repository: ref.watch(dexRepositoryProvider));
});
