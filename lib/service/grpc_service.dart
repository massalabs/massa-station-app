// This file is part of the Massa project.
// This file contains the implementation of the GrpcService interface.
// It provides methods for making gRPC calls to the Massa network.
// The GrpcServiceImpl class implements the GrpcService interface and provides
// methods for making read-only and state-changing smart contract calls.
// The class uses the GRPCPublicClient to interact with the Massa network.
// It also includes error handling for network requests and response parsing.
// The GrpcServiceImpl class is a singleton and is initialized with the gRPC host and port.

// The class is part of the Massa Wallet project and is licensed under the MIT License.

import 'package:flutter/foundation.dart';
import 'package:massa/massa.dart';
import 'package:massa/src/grpc/generated/public.pbgrpc.dart';
import 'package:mug/env/env.dart';

abstract interface class GrpcService {
  /// read only smart contract call
  Future<Uint8List> scReadOnlyCall(
      {required double maximumGas,
      required String smartContracAddress,
      required String functionName,
      required Uint8List functionParameters});

  Future<Uint8List> scCall(
      {required Account account,
      required double fee,
      required double maximumGas,
      required double coins,
      required String smartContracAddress,
      required String functionName,
      required Uint8List functionParameters});
}

class GrpcServiceImpl implements GrpcService {
  final _grpc = GRPCPublicClient(Env.grpcHost, Env.grpcPort);

  @override
  Future<Uint8List> scReadOnlyCall(
      {required double maximumGas,
      required String smartContracAddress,
      required String functionName,
      required Uint8List functionParameters}) async {
    try {
      final response = await _grpc.executeReadOnlyCall(
          minimumFee, maximumGas, smartContracAddress, functionName, functionParameters);
      return Uint8List.fromList(response.callResult);
    } catch (error) {
      throw Exception(error);
    }
  }

  @override
  Future<Uint8List> scCall(
      {required Account account,
      required double fee,
      required double maximumGas,
      required double coins,
      required String smartContracAddress,
      required String functionName,
      required Uint8List functionParameters}) async {
    try {
      final status = await _grpc.getStatus();
      print('status: ${status.toProto3Json()}');
      final expirePeriod = status.lastExecutedFinalSlot.period + status.config.operationValidityPeriods * 10;

      final operation = await callSC(
          account, smartContracAddress, functionName, functionParameters, fee, maximumGas, coins, expirePeriod.toInt());
      Uint8List data = Uint8List.fromList([]);

      await for (final resp in _grpc.sendOperations([operation])) {
        final opID = resp.operationIds.operationIds[0];
        while (true) {
          final filter = ScExecutionEventsFilter(originalOperationId: opID);
          final event = await _grpc.getScExecutionEvents([filter]);

          if (event.isNotEmpty) {
            var dataString = bytesToUtf8String(Uint8List.fromList(event[0].data));
            data = Uint8List.fromList(event[0].data);
            break;
          }
        }
        break;
      }
      return data;
    } catch (error) {
      throw Exception(error);
    }
  }
}
