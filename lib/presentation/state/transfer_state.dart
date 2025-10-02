// Project imports:
import 'package:mug/domain/entity/entity.dart';

sealed class TransferState {}

final class TransferInitial extends TransferState {}

final class TransferLoading extends TransferState {}

final class TransferSubmitting extends TransferState {
  final String sendingAddress;
  final String recipientAddress;
  final double amount;
  final double fee;

  TransferSubmitting({
    required this.sendingAddress,
    required this.recipientAddress,
    required this.amount,
    required this.fee,
  });
}

final class TransferSubmitted extends TransferState {
  final String sendingAddress;
  final String recipientAddress;
  final double amount;
  final double fee;
  final String operationId;

  TransferSubmitted({
    required this.sendingAddress,
    required this.recipientAddress,
    required this.amount,
    required this.fee,
    required this.operationId,
  });
}

final class TransferWaitingConfirmation extends TransferState {
  final String sendingAddress;
  final String recipientAddress;
  final double amount;
  final double fee;
  final String operationId;

  TransferWaitingConfirmation({
    required this.sendingAddress,
    required this.recipientAddress,
    required this.amount,
    required this.fee,
    required this.operationId,
  });
}

final class TransferIncludedInBlock extends TransferState {
  final String sendingAddress;
  final String recipientAddress;
  final double amount;
  final double fee;
  final String operationId;
  final String blockId;

  TransferIncludedInBlock({
    required this.sendingAddress,
    required this.recipientAddress,
    required this.amount,
    required this.fee,
    required this.operationId,
    required this.blockId,
  });
}

final class TransferSuccess extends TransferState {
  final TransferEntity transferEntity;
  TransferSuccess({required this.transferEntity});
}

final class TransferFailure extends TransferState {
  final String message;
  TransferFailure({required this.message});
}
