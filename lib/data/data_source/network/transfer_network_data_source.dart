// Package imports:
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:massa/src/grpc/generated/public.pb.dart';
import 'package:mug/data/data_source/explorer_data_source.dart';
import 'package:mug/data/data_source/network/explorer_network_data_source_impl.dart';
import 'package:mug/data/data_source/transfer_data_source.dart';
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/env/env.dart';
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
    String senderAddress,
    String recipientAddress,
    double amount, {
    Function(String operationId)? onOperationSubmitted,
    Function(String operationId)? onWaitingConfirmation,
    Function(String operationId, String blockId)? onIncludedInBlock,
  }) async {
    try {
      final privateKey = await localStorageService.getWalletKey(senderAddress);

      // Determine network type from grpcHost
      final networkType = Env.grpcHost.contains('buildnet') ? NetworkType.BUILDNET : NetworkType.MAINNET;

      final account = await Wallet().addAccountFromSecretKey(
          privateKey!, AddressType.user, networkType);

      // Create gRPC client
      final grpc = GRPCPublicClient(Env.grpcHost, Env.grpcPort);

      // Get status to calculate expiry period
      final status = await grpc.getStatus();
      final expirePeriod = status.lastExecutedFinalSlot.period + status.config.operationValidityPeriods;

      // Create transaction using Massa's sendTransaction
      final tx = await sendTransaction(account, recipientAddress, amount, minimumFee, expirePeriod.toInt());

      String operationID = "";
      bool isTransfered = false;

      // Send operation and get operation ID
      await for (final resp in grpc.sendOperations([tx])) {
        // Check for errors in response
        if (resp.hasError()) {
          throw Exception('Transfer failed: ${resp.error.message}');
        }

        if (resp.hasOperationIds() && resp.operationIds.operationIds.isNotEmpty) {
          operationID = resp.operationIds.operationIds[0];

          // Notify that operation was submitted
          if (onOperationSubmitted != null) {
            onOperationSubmitted(operationID);
            await Future.delayed(const Duration(seconds: 1));
          }

          // Notify waiting for confirmation
          if (onWaitingConfirmation != null) {
            onWaitingConfirmation(operationID);
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // Wait for final status with timeout
          final filter = NewSlotExecutionOutputsFilter(
            executedOpsChangesFilter: ExecutedOpsChangesFilter(operationId: operationID)
          );

          bool timeoutReached = false;
          final timeoutTimer = Timer(const Duration(seconds: 160), () {
            timeoutReached = true;
          });

          await for (var execResp in grpc.newSlotExecutionOutputs(filters: [filter])) {
            // Check different execution statuses
            if (execResp.status == ExecutionOutputStatus.EXECUTION_OUTPUT_STATUS_CANDIDATE) {
              if (onIncludedInBlock != null && execResp.executionOutput.hasBlockId()) {
                final blockId = execResp.executionOutput.blockId.value;
                onIncludedInBlock(operationID, blockId);
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } else if (execResp.status == ExecutionOutputStatus.EXECUTION_OUTPUT_STATUS_FINAL) {
              timeoutTimer.cancel();
              isTransfered = true;
              break;
            }

            if (timeoutReached) {
              break;
            }
          }

          timeoutTimer.cancel();
        }
        break;
      }

      final transferEntity = TransferEntity(
        amount: amount,
        sendingAddress: account.address(),
        recipientAddress: recipientAddress,
        operationID: operationID,
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
