// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/domain/entity/staker_entity.dart';
import 'package:mug/domain/usecase/explorer_use_case.dart';
import 'package:mug/domain/usecase/explorer_use_case_impl.dart';
import 'package:mug/presentation/state/staker_state.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class StakerProvider extends StateNotifier<StakerState> {
  StakerProvider() : super(StakerInitial());
  Future<void> getStakers(int pageNumber);
  void filterStakers(String address);
}

base class ExplorerProviderImpl extends StateNotifier<StakerState> implements StakerProvider {
  final ExplorerUseCase useCase;
  late Result<StakersEntity, Exception> result;
  ExplorerProviderImpl({
    required this.useCase,
  }) : super(StakerInitial());

  @override
  Future<void> getStakers(int pageNumber) async {
    state = StakerLoading();
    result = await useCase.getStakers(pageNumber);
    final response = switch (result) {
      Success(value: final response) => StakersSuccess(stakers: response),
      Failure(exception: final exception) => StakerFailure(message: 'Something went wrong: $exception'),
    };

    state = response;
    _debug();
  }

  @override
  void filterStakers(String address) async {
    if (address.isEmpty) {
      final response = switch (result) {
        Success(value: final response) => StakersSuccess(stakers: response),
        Failure(exception: final exception) => StakerFailure(message: 'Something went wrong: $exception'),
      };
      state = response;
    } else {
      switch (result) {
        case Success(value: final response):
          final filtered = response.stakers
              .where((element) => element.address.toString().toLowerCase().contains(address.toString().toLowerCase()))
              .toSet()
              .toList();
          final filterdStakers =
              StakersEntity(stakerNumbers: response.stakerNumbers, totalRolls: response.totalRolls, stakers: filtered);
          state = StakersSuccess(stakers: filterdStakers);
        case Failure(exception: final exception):
          state = StakerFailure(message: 'Something went wrong: $exception');
      }
    }
  }

  void _debug() {
    log('staker state: $state');
  }
}

final stakerProvider = StateNotifierProvider<StakerProvider, StakerState>((ref) {
  return ExplorerProviderImpl(useCase: ref.watch(explorerUseCaseProvider));
});
