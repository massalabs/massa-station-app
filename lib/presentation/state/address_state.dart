// Project imports:
import 'package:mug/domain/entity/address_entity.dart';

sealed class AddressState {}

final class AddressInitial extends AddressState {}

final class AddressLoading extends AddressState {}

final class AddressSuccess extends AddressState {
  final AddressEntity addressEntity;
  AddressSuccess({required this.addressEntity});
}

final class AddressFailure extends AddressState {
  final String message;
  AddressFailure({required this.message});
}
