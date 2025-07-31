// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/domain/usecase/explorer_use_case.dart';
import 'package:mug/domain/usecase/explorer_use_case_impl.dart';
import 'package:mug/presentation/state/operation_state.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class OperationProvider extends StateNotifier<OperationState> {
  OperationProvider() : super(OperationInitial());
  Future<void> getOperation(String address);
}

base class OperationProviderImpl extends StateNotifier<OperationState> implements OperationProvider {
  final ExplorerUseCase useCase;

  OperationProviderImpl({
    required this.useCase,
  }) : super(OperationInitial());

  @override
  Future<void> getOperation(String hash) async {
    state = OperationLoading();
    final result = await useCase.getOperation(hash);
    final response = switch (result) {
      Success(value: final response) => OperationSuccess(operationEntity: response),
      Failure(exception: final exception) => OperationFailure(message: 'Something went wrong: $exception'),
    };
    state = response;
    _debug();
  }

  void _debug() {
    log('staker state: $state');
  }
}

final operationProvider = StateNotifierProvider<OperationProvider, OperationState>((ref) {
  return OperationProviderImpl(useCase: ref.watch(explorerUseCaseProvider));
});
