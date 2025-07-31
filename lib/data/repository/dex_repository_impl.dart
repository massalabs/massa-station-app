// Package imports:
import 'package:dusa/dusa.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/data/data_source/dex_data_source.dart';
import 'package:mug/domain/entity/entity.dart';

// Project imports:
import 'package:mug/domain/repository/dex_repository.dart';
import 'package:mug/utils/exception_handling.dart';

import '../data_source/network/dex_network_data_source.dart';

class DexRepositoryImpl implements DexRepository {
  final DexDataSource dataSource;

  DexRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<Result<QuoterEntity, Exception>> findBestPathFromAmountIn(
      String accountAddress, TokenName token1, TokenName token2, double amount) async {
    try {
      return await dataSource.findBestPathFromAmountIn(accountAddress, token1, token2, amount);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<QuoterEntity, Exception>> findBestPathFromAmountOut(
      String accountAddress, TokenName token1, TokenName token2, double amount) async {
    try {
      return await dataSource.findBestPathFromAmountOut(accountAddress, token1, token2, amount);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<AddressEntity, Exception>> getMASBalance(
    String accountAddress,
  ) async {
    try {
      return await dataSource.getMASBalance(
        accountAddress,
      );
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<BigInt, Exception>> getTokenBalance(String accountAddress, TokenName tokenType) async {
    try {
      return await dataSource.getTokenBalance(accountAddress, tokenType);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<(String, bool), Exception>> swapToken(String accountAddress, SwapEntity data) async {
    try {
      return await dataSource.swapToken(accountAddress, data);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final dexRepositoryProvider = Provider<DexRepository>((ref) {
  return DexRepositoryImpl(dataSource: ref.watch(dexNetworkDatasourceProvider));
});
