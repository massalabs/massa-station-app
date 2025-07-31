// Project imports:
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/utils/exception_handling.dart';

abstract interface class TransferUseCase {
  Future<Result<TransferEntity, Exception>> transfer(String senderAddress, String recipientAddress, double amount);
}
