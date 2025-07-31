// Project imports:
import 'package:mug/domain/entity/operation_entity.dart';

sealed class OperationState {}

final class OperationInitial extends OperationState {}

final class OperationLoading extends OperationState {}

final class OperationSuccess extends OperationState {
  final OperationEntity operationEntity;
  OperationSuccess({required this.operationEntity});
}

final class OperationFailure extends OperationState {
  final String message;
  OperationFailure({required this.message});
}
