// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/domain/usecase/explorer_use_case.dart';
import 'package:mug/domain/usecase/explorer_use_case_impl.dart';
import 'package:mug/presentation/state/block_state.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class BlockProvider extends StateNotifier<BlockState> {
  BlockProvider() : super(BlockInitial());
  Future<void> getBlock(String address);
}

base class BlockProviderImpl extends StateNotifier<BlockState> implements BlockProvider {
  final ExplorerUseCase useCase;

  BlockProviderImpl({
    required this.useCase,
  }) : super(BlockInitial());

  @override
  Future<void> getBlock(String address) async {
    state = BlockLoading();
    final result = await useCase.getBlock(address);
    final response = switch (result) {
      Success(value: final response) => BlockSuccess(blockEntity: response),
      Failure(exception: final exception) => BlockFailure(message: 'Something went wrong: $exception'),
    };
    state = response;
    _debug();
  }

  void _debug() {
    log('staker state: $state');
  }
}

final blockProvider = StateNotifierProvider<BlockProvider, BlockState>((ref) {
  print("block provider initalised...");
  return BlockProviderImpl(useCase: ref.watch(explorerUseCaseProvider));
});
