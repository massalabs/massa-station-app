// Project imports:
import 'package:mug/domain/entity/wallet_entity.dart';

sealed class WalletImportState {}

final class WalletInitial extends WalletImportState {}

final class WalletImporting extends WalletImportState {}

final class WalletSuccess extends WalletImportState {
  final WalletEntity wallet;
  WalletSuccess({required this.wallet});
}

final class WalletFailure extends WalletImportState {
  final String message;
  WalletFailure({required this.message});
}
