// Package imports:
import 'package:dusa/dusa.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/constants/asset_names.dart';
import 'package:mug/data/repository/dex_repository_impl.dart';

// Project imports:
import 'package:mug/data/repository/explorer_repository_impl.dart';
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/domain/repository/dex_repository.dart';
import 'package:mug/domain/repository/explorer_repository.dart';
import 'package:mug/domain/usecase/explorer_use_case.dart';
import 'package:mug/utils/exception_handling.dart';

class ExplorerUseCaseImpl implements ExplorerUseCase {
  final ExplorerRepository repository;
  final DexRepository dexRepository;

  ExplorerUseCaseImpl({
    required this.repository,
    required this.dexRepository,
  });

  @override
  Future<Result<AddressEntity, Exception>> getAddress(String address, bool getTokenBalance) async {
    List<TokenBalance> tokenBalances = [];
    try {
      if (getTokenBalance) {
        //get WMAS token
        final wmasResult = await dexRepository.getTokenBalance(address, TokenName.WMAS);
        if (wmasResult is Success) {
          BigInt value = (wmasResult as Success).value;
          tokenBalances.add(
            TokenBalance(
                name: TokenName.WMAS,
                balance: bigIntToDecimal(value, getTokenDecimal(TokenName.WMAS)),
                iconPath: AssetName.wmas),
          );
        } else {
          tokenBalances.add(const TokenBalance(name: TokenName.WMAS, balance: 0.0, iconPath: AssetName.wmas));
        }

        //get USDC token
        final usdcResult = await dexRepository.getTokenBalance(address, TokenName.USDC);
        if (usdcResult is Success) {
          BigInt value = (usdcResult as Success).value;
          tokenBalances.add(TokenBalance(
              name: TokenName.USDC,
              balance: bigIntToDecimal(value, getTokenDecimal(TokenName.USDC)),
              iconPath: AssetName.usdc));
        } else {
          tokenBalances.add(const TokenBalance(name: TokenName.USDC, balance: 0.0, iconPath: AssetName.usdc));
        }

        //get WETH token
        final wethResult = await dexRepository.getTokenBalance(address, TokenName.WETH);
        if (wethResult is Success) {
          BigInt value = (wethResult as Success).value;
          tokenBalances.add(TokenBalance(
              name: TokenName.WETH,
              balance: bigIntToDecimal(value, getTokenDecimal(TokenName.WETH)),
              iconPath: AssetName.eth));
        } else {
          tokenBalances.add(const TokenBalance(name: TokenName.WETH, balance: 0.0, iconPath: AssetName.eth));
        }
      }

      final result = await repository.getAddress(address);
      return switch (result) {
        Success(value: final value) => Success(value: value.copyWith(tokenBalances: tokenBalances)),
        Failure(exception: final exception) =>
          Failure(exception: Exception("unable to get address information: $exception"))
      };
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<BlockEntity, Exception>> getBlock(String hash) async {
    try {
      return await repository.getBlock(hash);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<StakersEntity, Exception>> getStakers(int pageNumber) async {
    try {
      return await repository.getStakers(pageNumber);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<OperationEntity, Exception>> getOperation(String hash) async {
    try {
      return await repository.getOperation(hash);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<DomainEntity, Exception>> getDomain(String domainName) async {
    try {
      return await repository.getDomain(domainName);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<(String, bool), Exception>> buyDomain(String domainName, double domainPrice) async {
    try {
      return await repository.buyDomain(domainName, domainPrice);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final explorerUseCaseProvider = Provider<ExplorerUseCase>((ref) {
  return ExplorerUseCaseImpl(
      repository: ref.watch(explorerRepositoryProvider), dexRepository: ref.watch(dexRepositoryProvider));
});
