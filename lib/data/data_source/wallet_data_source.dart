// Project imports:
import 'package:mug/domain/entity/address_entity.dart';
import 'package:mug/utils/exception_handling.dart';

abstract interface class WalletDataSource {
  Future<Result<AddressEntity, Exception>> getAddress(String address);
  Future<Result<List<AddressEntity>, Exception>> getAddresses(List<String> addresses);
  Future<Result<(String, bool), Exception>> transfer(double amount, String recipientAddress);
}
