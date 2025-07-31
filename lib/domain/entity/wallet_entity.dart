// Project imports:
import 'package:mug/domain/entity/address_entity.dart';

class WalletEntity {
  final String address;
  final String encryptedKey;
  final String? name;
  AddressEntity? addressInformation;

  WalletEntity({
    required this.address,
    required this.encryptedKey,
    this.name,
    this.addressInformation,
  });
}
