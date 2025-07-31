// Package imports:
import 'dart:async';

import 'package:dusa/dusa.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/data/data_source/dex_data_source.dart';
import 'package:mug/data/data_source/explorer_data_source.dart';
import 'package:mug/data/data_source/network/explorer_network_data_source_impl.dart';
import 'package:mug/domain/entity/address_entity.dart';

// Project imports:
import 'package:mug/domain/entity/quoter_entity.dart';
import 'package:mug/domain/entity/swap_entity.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/service/smart_contract_client.dart';
import 'package:mug/utils/exception_handling.dart';

class DexNetworkDataSourceImpl implements DexDataSource {
  final SmartContractService? smartContractService;
  final ExplorerDataSource explorerDataSource;
  final LocalStorageService localStorageService;

  DexNetworkDataSourceImpl(
      {this.smartContractService, required this.explorerDataSource, required this.localStorageService});

  @override
  Future<Result<QuoterEntity, Exception>> findBestPathFromAmountIn(
      String accountAddress, TokenName token1, TokenName token2, double amount) async {
    try {
      await _updateSmartcontractClientAccount(accountAddress);
      final quoter = Quoter(smartContractService!.client);
      final amountIn = doubleToMassaInt(amount);
      final (router, pair, binSteps, amounts, amountWithoutSlippage, fees) =
          await quoter.findBestPathFromAmountIn(token1, token2, BigInt.from(amountIn));
      final quoterEntinty = QuoterEntity(
          router: router,
          pair: pair,
          binSteps: binSteps,
          amounts: amounts,
          amountsWithoutSlipage: amountWithoutSlippage,
          fees: fees);
      return Success(value: quoterEntinty);
    } on Exception catch (error) {
      if (kDebugMode) {
        print(error.toString());
      }
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<QuoterEntity, Exception>> findBestPathFromAmountOut(
      String accountAddress, TokenName token1, TokenName token2, double amount) async {
    try {
      await _updateSmartcontractClientAccount(accountAddress);
      final quoter = Quoter(smartContractService!.client);
      final amountOut = doubleToMassaInt(amount);
      final (router, pair, binSteps, amounts, amountWithoutSlippage, fees) =
          await quoter.findBestPathFromAmountIn(token1, token2, BigInt.from(amountOut));

      final quoterEntinty = QuoterEntity(
          router: router,
          pair: pair,
          binSteps: binSteps,
          amounts: amounts,
          amountsWithoutSlipage: amountWithoutSlippage,
          fees: fees);
      return Success(value: quoterEntinty);
    } on Exception catch (error) {
      if (kDebugMode) {
        print(error.toString());
      }
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<AddressEntity, Exception>> getMASBalance(String accountAddress) async {
    try {
      await _updateSmartcontractClientAccount(accountAddress);
      final balance = await explorerDataSource.getAddress(accountAddress);
      return balance;
    } on Exception catch (error) {
      if (kDebugMode) {
        print(error.toString());
      }
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<BigInt, Exception>> getTokenBalance(String accountAddress, TokenName tokenType) async {
    await _updateSmartcontractClientAccount(accountAddress);
    final token = Token(grpc: smartContractService!.client, token: tokenType);
    try {
      if (kDebugMode) {
        print('DEBUG: Getting balance for token: $tokenType');
        print('DEBUG: Wallet address: $accountAddress');
        print('DEBUG: Smart contract account address: ${smartContractService!.account.address()}');
      }
      final resp = await token.balanceOf(accountAddress);
      if (kDebugMode) {
        print('DEBUG: Raw BigInt balance for $tokenType: $resp');
      }
      return Success(value: resp);
    } on Exception catch (error) {
      if (kDebugMode) {
        print('DEBUG: Error getting token balance: $error');
      }
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<(String, bool), Exception>> swapToken(String accountAddress, SwapEntity data) async {
    //final address = smartContractService!.account.address();
    try {
      await _updateSmartcontractClientAccount(accountAddress);
      final swap = Swap(smartContractService!.client);

      if (data.selectedToken1 == "MAS" && data.selectedToken2 == "WMAS") {
        final (operation, isExecuted) = await swap.wrap(data.amountIn);
        return Success(value: (operation, isExecuted));
      } else if (data.selectedToken1 == "WMAS" && data.selectedToken2 == "MAS") {
        final (operation, isExecuted) = await swap.unwrap(data.amountIn);
        return Success(value: (operation, isExecuted));
      } else if (data.token1 == TokenName.WMAS) {
        final (operation, isExecuted) = await swap.swapExactMASForTokens(
          fromMAS(data.amountIn),
          decimalToBigInt(data.amountOut, getTokenDecimal(data.token2)),
          data.binSteps!,
          data.tokenPath!,
          accountAddress,
          CommonConstants.txDeadline,
        );
        return Success(value: (operation, isExecuted));
      } else {
        final quoter = Quoter(smartContractService!.client);
        final amountOut = doubleToMassaInt(data.amountOut);
        final (router, pair, binSteps, amounts, amountWithoutSlippage, fees) =
            await quoter.findBestPathFromAmountOut(data.token1, data.token2, BigInt.from(amountOut));

        final amountIn = bigIntToDecimal(amounts[0], getTokenDecimal(data.token1));
        final amountInWithSlippage = maximumAmoutIn(amountIn, 0.5);
        final amountBigInt = decimalToBigInt(amountInWithSlippage, getTokenDecimal(data.token1));
        final token = Token(grpc: smartContractService!.client, token: data.token1);
        await token.increaseAllowance(amountBigInt);

        final (operation, isExecuted) = await swap.swapTokensForExactMAS(
          amountBigInt,
          amounts[1],
          binSteps,
          router,
          accountAddress,
          CommonConstants.txDeadline,
        );
        return Success(value: (operation, isExecuted));
      }
    } on Exception catch (error) {
      if (kDebugMode) {
        print(error.toString());
      }
      return Failure(exception: error);
    }
  }

  Future<void> _updateSmartcontractClientAccount(String address) async {
    if (smartContractService!.account.address() == address) {
      return;
    }
    final privateKey = await localStorageService.getWalletKey(address);
    final account = await Wallet().addAccountFromSecretKey(
        privateKey!, AddressType.user, smartContractService!.isBuildnet ? NetworkType.BUILDNET : NetworkType.MAINNET);
    smartContractService!.updateAccount(account.privateKey());
  }
}

final dexNetworkDatasourceProvider = Provider<DexDataSource>((ref) {
  return DexNetworkDataSourceImpl(
    smartContractService: ref.watch(smartContractServiceProvider),
    explorerDataSource: ref.watch(explorerNetworkDatasourceProvider),
    localStorageService: ref.watch(localStorageServiceProvider),
  );
});
