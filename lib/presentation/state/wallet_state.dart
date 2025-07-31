// Project imports:
import 'package:mug/domain/entity/address_entity.dart';

sealed class WalletState {}

final class WalletLoading extends WalletState {}

final class WalletSuccess extends WalletState {
  final AddressEntity addressEntity;
  WalletSuccess({required this.addressEntity});
}

final class WalletFailure extends WalletState {
  final String message;
  WalletFailure({required this.message});
}
