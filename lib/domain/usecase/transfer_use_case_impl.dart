// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/domain/entity/entity.dart';

// Project imports:
import 'package:mug/data/repository/transfer_repository_impl.dart';
import 'package:mug/domain/repository/transfer_repository.dart';
import 'package:mug/domain/usecase/transfer_use_case.dart';
import 'package:mug/utils/exception_handling.dart';

class TransferUseCaseImpl implements TransferUseCase {
  final TransferRepository repository;

  TransferUseCaseImpl({
    required this.repository,
  });

  @override
  Future<Result<TransferEntity, Exception>> transfer(
      String senderAddress, String recipientAddress, double amount) async {
    try {
      return await repository.transfer(senderAddress, recipientAddress, amount);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final transferUseCaseProvider = Provider<TransferUseCase>((ref) {
  return TransferUseCaseImpl(repository: ref.watch(transferRepositoryProvider));
});
