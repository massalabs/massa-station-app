// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';

// Project imports:
import 'package:mug/data/data_source/wallet_data_source.dart';
import 'package:mug/domain/entity/address_entity.dart';
import 'package:mug/service/jrpc_service.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/service/smart_contract_client.dart';
import 'package:mug/utils/exception_handling.dart';

class WalletNetworkDataSourceImpl implements WalletDataSource {
  final SmartContractService? smartContractService;
  final JrpcService jrpcService;
  final LocalStorageService storageService;

  WalletNetworkDataSourceImpl({
    required this.smartContractService,
    required this.jrpcService,
    required this.storageService,
  });

  @override
  Future<Result<AddressEntity, Exception>> getAddress(String address) async {
    try {
      final Address? response = await jrpcService.getAddress(address);
      if (response != null) {
        final addressData = AddressEntity(
          address: response.address,
          thread: response.thread,
          finalBalance: response.finalBalance,
          candidateBalance: response.candidateBalance,
          finalRolls: response.finalRollCount,
          candidateRolls: response.candidateRollCount,
          activeRoles: response.cycleInfos.last.activeRolls,
          createdBlocks: response.createdBlocks.length,
          createdEndorsements: response.createdEndorsements.length,
        );
        return Success(value: addressData);
      } else {
        return Failure(exception: Exception("Could not retrieve address information"));
      }
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<List<AddressEntity>, Exception>> getAddresses(List<String> addresses) async {
    try {
      final List<Address>? response = await jrpcService.getAddresses(addresses);
      if (response != null) {
        List<AddressEntity> resultAddresses = [];
        for (var a in response) {
          final addressData = AddressEntity(
            address: a.address,
            thread: a.thread,
            finalBalance: a.finalBalance,
            candidateBalance: a.candidateBalance,
            finalRolls: a.finalRollCount,
            candidateRolls: a.candidateRollCount,
            activeRoles: a.cycleInfos.last.activeRolls,
            createdBlocks: a.createdBlocks.length,
            createdEndorsements: a.createdEndorsements.length,
          );
          resultAddresses.add(addressData);
        }

        return Success(value: resultAddresses);
      } else {
        return Failure(exception: Exception("Could not retrieve address information"));
      }
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<(String, bool), Exception>> transfer(double amount, String recipientAddress) async {
    try {
      final (operation, isExecuted) = await smartContractService!.client.transfer(
          account: smartContractService!.account, recipientAddress: recipientAddress, amount: amount, fee: minimumFee);
      return Success(value: (operation, isExecuted));
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final walletNetworkDatasourceProvider = Provider<WalletDataSource>((ref) {
  return WalletNetworkDataSourceImpl(
    smartContractService: ref.watch(smartContractServiceProvider),
    jrpcService: ref.watch(jrpcServiceProvider),
    storageService: ref.watch(localStorageServiceProvider),
  );
});
