// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/constants/constants.dart';

// Project imports:
import 'package:mug/data/data_source/explorer_data_source.dart';
import 'package:mug/data/model/address_history.dart';
import 'package:mug/data/model/block.dart';
import 'package:mug/data/model/domain.dart';
import 'package:mug/data/model/stakers.dart';
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/service/explorer_api.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/service/smart_contract_client.dart';
import 'package:mug/utils/exception_handling.dart';

class ExplorerNetworkDataSourceImpl implements ExplorerDataSource {
  final ExplorerApi api;
  final SmartContractService? smartContractService;

  ExplorerNetworkDataSourceImpl({required this.api, this.smartContractService});

  @override
  Future<Result<AddressEntity, Exception>> getAddress(String address) async {
    try {
      final Address? response = await api.getAddress(address);
      AddressTransactionHistory? txHistory = await api.getAddressTransactionHistory(address, true, true);

      if (txHistory != null) {
        txHistory.combinedHistory = [...?txHistory.operationsCreated, ...?txHistory.operationsReceived];
        txHistory.combinedHistory!.sort((a, b) {
          // Parse the timestamps as integers and then to DateTime
          DateTime dateA = DateTime.fromMillisecondsSinceEpoch(int.parse(a.blockTime!));
          DateTime dateB = DateTime.fromMillisecondsSinceEpoch(int.parse(b.blockTime!));
          return dateB.compareTo(dateA); // Descending order
        });
      }

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
            transactionHistory: txHistory);

        return Success(value: addressData);
      } else {
        return Failure(exception: Exception("Could not retrieve address information"));
      }
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<BlockEntity, Exception>> getBlock(String hash) async {
    try {
      final ExplorerBlock? response = await api.getBlock(hash);
      if (response != null) {
        List<TransactionEntity> latestOperations = [];
        response.latestOps?.forEach(
          (element) {
            final op = TransactionEntity(
              hash: element.hash,
              blockTime: element.blockTime,
              status: element.status,
              type: element.type,
              from: element.from,
              to: element.to,
              value: element.value,
              transactionFee: element.transactionFee,
              opExecStatus: element.opExecStatus,
            );
            latestOperations.add(op);
          },
        );

        final addressData = BlockEntity(
            hash: response.hash,
            isFinal: response.isFinal,
            blockTime: response.blockTime,
            creatorAddress: response.creatorAddress,
            operationCount: response.operationCount,
            endorsements: response.endorsements,
            parents: response.parents,
            isInBlockclique: response.isInBlockclique,
            blockReward: response.blockReward,
            blockSize: response.blockSize,
            thread: response.thread,
            period: response.period,
            signature: response.signature,
            creatorPublicKey: response.creatorPublicKey,
            latestOps: latestOperations);
        return Success(value: addressData);
      } else {
        return Failure(exception: Exception("Could not retrieve address information"));
      }
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<StakersEntity, Exception>> getStakers(int pageNumber) async {
    try {
      final ExplorerStakers? response = await api.getStakers(pageNumber);
      if (response == null) {
        return Failure(exception: Exception("No data found 111"));
      }
      List<StakerEntity> data = [];
      var count = 1;
      response.stakers?.forEach(
        (element) {
          data.add(StakerEntity(
              address: element.hash!,
              rank: Constants.pageSize * pageNumber + count,
              rolls: element.rollsCount!,
              ownershipPercentage: element.percentageOfShare!,
              estimatedDailyReward: element.percentageOfShare! * Constants.totalDailyReward / 100.00));
          count++;
        },
      );

      final stakers =
          StakersEntity(stakerNumbers: response.totalStakers!, totalRolls: response.totalRolls!, stakers: data);
      return Success(value: stakers);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<OperationEntity, Exception>> getOperation(String hash) async {
    try {
      final Operation? response = await api.getOperation(hash);
      if (response == null) {
        return Failure(exception: Exception("No data found"));
      }

      OperationEntityContent content = OperationEntityContent(
          fee: response.operation!.content.fee,
          expirePeriod: response.operation!.content.expirePeriod,
          op: OperationTypeEntity());
      BuyRollOperationEntity buyRolls;
      SellRollOperationEntity sellRolls;
      TransactionOperationEntity tx;
      CallSCOperationEntity callSC;

      if (response.operation?.content.op.transaction != null) {
        tx = TransactionOperationEntity(
            recipientAddress: response.operation!.content.op.transaction!.recipientAddress,
            amount: response.operation!.content.op.transaction!.amount);
        content.op.transaction = tx;
      }
      if (response.operation?.content.op.buyRoll != null) {
        buyRolls = BuyRollOperationEntity(rollCount: response.operation!.content.op.buyRoll!.rollCount);
        content.op.buyRoll = buyRolls;
      }
      if (response.operation?.content.op.sellRoll != null) {
        sellRolls = SellRollOperationEntity(rollCount: response.operation!.content.op.sellRoll!.rollCount);
        content.op.sellRoll = sellRolls;
      }
      if (response.operation?.content.op.callSC != null) {
        callSC = CallSCOperationEntity(
            targetAddr: response.operation!.content.op.callSC!.targetAddr,
            coins: response.operation!.content.op.callSC!.coins,
            param: response.operation!.content.op.callSC!.param,
            maxGas: response.operation!.content.op.callSC!.maxGas,
            targetFunc: response.operation!.content.op.callSC!.targetFunc);
        content.op.callSC = callSC;
      }

      OperationEntityData data = OperationEntityData(
          contentCreatorAddress: response.operation!.contentCreatorAddress,
          contentCreatorPubKey: response.operation!.contentCreatorPubKey,
          signature: response.operation!.signature,
          content: content);

      OperationEntity entity = OperationEntity(
        id: hash,
        isFinal: response.isFinal,
        inPool: response.inPool,
        inBlocks: response.inBlocks,
        thread: response.thread,
        opExecutionStatus: response.opExecutionStatus,
        operation: data,
      );

      return Success(value: entity);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<DomainEntity, Exception>> getDomain(String domainName) async {
    try {
      final DomainDetails? response = await api.getDomainDetails(domainName);
      if (response == null) {
        return Failure(exception: Exception("No data found"));
      }
      final domain = DomainEntity(
          targetAddress: response.targetAddress!, tokenId: response.tokenId!, ownerAddress: response.ownerAddress!);
      return Success(value: domain);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<(String, bool), Exception>> buyDomain(String domainName, double domainPrice) async {
    try {
      final params = Args();
      params.addString(domainName); //domain name
      params.addString(smartContractService!.account.address()); //target address
      final (operation, isExecuted) = await smartContractService!.client.scCall(
          account: smartContractService!.account,
          functionName: "dnsAlloc",
          functionParameters: params.serialise(),
          smartContracAddress: CommonAddresses.MAINNET_DNS_ADDRESS.value,
          coins: domainPrice,
          fee: minimumFee,
          maximumGas: toMAS(BigInt.from(GasLimit.MAX_GAS_EXECUTE_SC.value)));
      return Success(value: (operation, isExecuted));
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final explorerNetworkDatasourceProvider = Provider<ExplorerDataSource>((ref) {
  return ExplorerNetworkDataSourceImpl(
    api: ref.watch(explorerApiServiceProvider),
    smartContractService: ref.watch(smartContractServiceProvider),
  );
});
