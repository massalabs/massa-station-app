// Project imports:
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/utils/exception_handling.dart';

abstract interface class TransferRepository {
  Future<Result<TransferEntity, Exception>> transfer(String senderAddress, String recipientAddress, double amount);
}
