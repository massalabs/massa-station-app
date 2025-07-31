// Dart imports:

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/domain/usecase/transfer_use_case.dart';
import 'package:mug/domain/usecase/transfer_use_case_impl.dart';
import 'package:mug/presentation/provider/screen_title_provider.dart';

// Project imports:
import 'package:mug/presentation/state/transfer_state.dart';
import 'package:mug/utils/exception_handling.dart';

abstract base class TransferProvider extends StateNotifier<TransferState> {
  TransferProvider(super._state);
  Future<void> transfer(String senderAddress, String recipientAddress, double amount);
  void resetState();
}

base class TransferProviderImpl extends StateNotifier<TransferState> implements TransferProvider {
  final TransferUseCase useCase;
  final Ref ref;
  TransferProviderImpl(this.ref, {required this.useCase}) : super(TransferInitial());

  @override
  Future<void> transfer(String senderAddress, String recipientAddress, double amount) async {
    state = TransferLoading();

    final result = await useCase.transfer(senderAddress, recipientAddress, amount);
    switch (result) {
      case Success(value: final value):
        ref.read(screenTitleProvider.notifier).updateTitle("Transfer Confirmation");
        state = TransferSuccess(transferEntity: value);
        break;
      case Failure():
        state = TransferFailure(message: "Failed to transfer fund");
    }
  }

  @override
  void resetState() {
    ref.read(screenTitleProvider.notifier).updateTitle("Fund Transfer");
    state = TransferInitial();
  }
}

final transferProvider = StateNotifierProvider<TransferProvider, TransferState>((ref) {
  return TransferProviderImpl(ref, useCase: ref.watch(transferUseCaseProvider));
});
