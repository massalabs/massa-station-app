// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/domain/usecase/explorer_use_case.dart';
import 'package:mug/domain/usecase/explorer_use_case_impl.dart';
import 'package:mug/presentation/state/address_state.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class AddressProvider extends StateNotifier<AddressState> {
  AddressProvider() : super(AddressInitial());
  Future<void> getAddress(String address, bool getTokenBalance);
}

base class AddressProviderImpl extends StateNotifier<AddressState> implements AddressProvider {
  final ExplorerUseCase useCase;

  AddressProviderImpl({
    required this.useCase,
  }) : super(AddressInitial());

  @override
  Future<void> getAddress(String address, bool getTokenBalance) async {
    state = AddressLoading();
    final result = await useCase.getAddress(address, getTokenBalance);
    final response = switch (result) {
      Success(value: final response) => AddressSuccess(addressEntity: response),
      Failure(exception: final exception) => AddressFailure(message: 'Something went wrong: $exception'),
    };
    state = response;
    _debug();
  }

  void _debug() {
    log('staker state: $state');
  }
}

final addressProvider = StateNotifierProvider<AddressProvider, AddressState>((ref) {
  print("address provider initalised...");
  return AddressProviderImpl(useCase: ref.watch(explorerUseCaseProvider));
});
