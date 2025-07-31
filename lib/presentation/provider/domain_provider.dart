// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/domain/usecase/explorer_use_case.dart';
import 'package:mug/domain/usecase/explorer_use_case_impl.dart';
import 'package:mug/presentation/state/domain_state.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class DomainProvider extends StateNotifier<DomainState> {
  DomainProvider() : super(DomainInitial());
  Future<void> getDomain(String domainName);
  Future<(String, bool)> buyDomain(String domainName, double domainPrice);
}

base class DomainProviderImpl extends StateNotifier<DomainState> implements DomainProvider {
  final ExplorerUseCase useCase;

  DomainProviderImpl({
    required this.useCase,
  }) : super(DomainInitial());

  @override
  Future<void> getDomain(String domainName) async {
    state = DomainLoading();
    final result = await useCase.getDomain(domainName);
    final response = switch (result) {
      Success(value: final response) => DomainSuccess(domainEntity: response),
      Failure(exception: final exception) => DomainFailure(message: 'Something went wrong: $exception'),
    };
    state = response;
    _debug();
  }

  @override
  Future<(String, bool)> buyDomain(String domainName, double domainPrice) async {
    final result = await useCase.buyDomain(domainName, domainPrice);
    final response = switch (result) {
      Success(value: final response) => response,
      Failure() => ("Something went wrong", false),
    };
    return response;
  }

  void _debug() {
    log('staker state: $state');
  }
}

final domainProvider = StateNotifierProvider<DomainProvider, DomainState>((ref) {
  return DomainProviderImpl(useCase: ref.watch(explorerUseCaseProvider));
});
