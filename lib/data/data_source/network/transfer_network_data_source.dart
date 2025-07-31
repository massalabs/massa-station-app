// Package imports:
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/data/data_source/explorer_data_source.dart';
import 'package:mug/data/data_source/network/explorer_network_data_source_impl.dart';
import 'package:mug/data/data_source/transfer_data_source.dart';
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/service/local_storage_service.dart';

// Project imports:
import 'package:mug/service/provider.dart';
import 'package:mug/service/smart_contract_client.dart';
import 'package:mug/utils/exception_handling.dart';

class TransferNetworkDataSourceImpl implements TransferDataSource {
  final SmartContractService? smartContractService;
  final ExplorerDataSource explorerDataSource;
  final LocalStorageService localStorageService;

  TransferNetworkDataSourceImpl(
      {this.smartContractService, required this.explorerDataSource, required this.localStorageService});

  @override
  Future<Result<TransferEntity, Exception>> transfer(
      String senderAddress, String recipientAddress, double amount) async {
    try {
      final privateKey = await localStorageService.getWalletKey(senderAddress);
      final account = await Wallet().addAccountFromSecretKey(
          privateKey!, AddressType.user, smartContractService!.isBuildnet ? NetworkType.BUILDNET : NetworkType.MAINNET);

      final (operation, isTransfered) = await smartContractService!.client
          .transfer(account: account, recipientAddress: recipientAddress, amount: amount, fee: minimumFee);
      final transferEntity = TransferEntity(
        amount: amount,
        sendingAddress: account.address(), //replace this with the acccount address
        recipientAddress: recipientAddress,
        operationID: operation,
        isTransfered: isTransfered,
      );
      return Success(value: transferEntity);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final transferNetworkDatasourceProvider = Provider<TransferDataSource>((ref) {
  return TransferNetworkDataSourceImpl(
    smartContractService: ref.watch(smartContractServiceProvider),
    explorerDataSource: ref.watch(explorerNetworkDatasourceProvider),
    localStorageService: ref.watch(localStorageServiceProvider),
  );
});
