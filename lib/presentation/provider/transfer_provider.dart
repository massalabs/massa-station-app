// Dart imports:

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/domain/usecase/transfer_use_case.dart';
import 'package:mug/domain/usecase/transfer_use_case_impl.dart';
import 'package:mug/presentation/provider/screen_title_provider.dart';
import 'package:mug/presentation/provider/setting_provider.dart';

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
    // Get fee from settings
    final fee = ref.read(settingProvider).feeAmount;

    // Show submitting state with transaction details
    state = TransferSubmitting(
      sendingAddress: senderAddress,
      recipientAddress: recipientAddress,
      amount: amount,
      fee: fee,
    );

    final result = await useCase.transfer(senderAddress, recipientAddress, amount,
      onOperationSubmitted: (String operationId) async {
        state = TransferSubmitted(
          sendingAddress: senderAddress,
          recipientAddress: recipientAddress,
          amount: amount,
          fee: fee,
          operationId: operationId,
        );
      },
      onWaitingConfirmation: (String operationId) async {
        state = TransferWaitingConfirmation(
          sendingAddress: senderAddress,
          recipientAddress: recipientAddress,
          amount: amount,
          fee: fee,
          operationId: operationId,
        );
      },
      onIncludedInBlock: (String operationId, String blockId) async {
        state = TransferIncludedInBlock(
          sendingAddress: senderAddress,
          recipientAddress: recipientAddress,
          amount: amount,
          fee: fee,
          operationId: operationId,
          blockId: blockId,
        );
      },
    );

    // Give a moment for the last state update to render
    await Future.delayed(const Duration(milliseconds: 100));

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
