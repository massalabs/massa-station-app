// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/data/data_source/network/transfer_network_data_source.dart';
import 'package:mug/data/data_source/transfer_data_source.dart';
import 'package:mug/domain/entity/entity.dart';

// Project imports:
import 'package:mug/domain/repository/transfer_repository.dart';
import 'package:mug/utils/exception_handling.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TransferDataSource dataSource;

  TransferRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<Result<TransferEntity, Exception>> transfer(
      String senderAddress, String recipientAddress, double amount) async {
    try {
      return await dataSource.transfer(senderAddress, recipientAddress, amount);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepositoryImpl(dataSource: ref.watch(transferNetworkDatasourceProvider));
});
