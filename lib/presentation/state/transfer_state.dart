// Project imports:
import 'package:mug/domain/entity/entity.dart';

sealed class TransferState {}

final class TransferInitial extends TransferState {}

final class TransferLoading extends TransferState {}

final class TransferSuccess extends TransferState {
  final TransferEntity transferEntity;
  TransferSuccess({required this.transferEntity});
}

final class TransferFailure extends TransferState {
  final String message;
  TransferFailure({required this.message});
}
