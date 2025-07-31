// Project imports:
import 'package:mug/data/model/wallet_model.dart';
import 'package:mug/utils/exception_handling.dart';

abstract interface class WalletUseCase {
  Future<Result<WalletData, Exception>> loadWallets();
  Future<Result<WalletData, Exception>> createWallet();
  Future<Result<WalletData, Exception>> restoreWallet(String privateKey);
  Future<Result<WalletData, Exception>> deleteWallet(String address);
  //Future<Result<bool, Exception>> setPassphrase(String passphrase);
  //Future<Result<String, Exception>> getPassphrase();
  //Future<Result<bool, Exception>> isPassphraseSet();
}
