// Project imports:

// Project imports:
import 'package:mug/domain/entity/address_entity.dart';
import 'package:mug/utils/exception_handling.dart';

abstract interface class WalletRepository {
  Future<Result<AddressEntity, Exception>> getAddress(String address);
  Future<Result<List<AddressEntity>, Exception>> getAddresses(List<String> addresses);
}
