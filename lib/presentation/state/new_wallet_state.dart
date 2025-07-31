// Project imports:
import 'package:mug/domain/entity/wallet_entity.dart';

sealed class NewWalletState {}

final class WalletInitial extends NewWalletState {}

final class WalletSaving extends NewWalletState {}

final class WalletSuccess extends NewWalletState {
  final WalletEntity wallet;
  WalletSuccess({required this.wallet});
}

final class WalletFailure extends NewWalletState {
  final String message;
  WalletFailure({required this.message});
}
