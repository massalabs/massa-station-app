import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mug/data/model/wallet_model.dart';
import 'package:mug/utils/encryption/aes_encryption.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageKeys {
  static const passphraseHash = 'passphrasehash';
  static const isThemeDark = 'isthemedark';
  static const keyboardIncognito = 'keyboardIcognito';
  static const isInactivityTimeoutOn = 'isInactivityTimeoutOn';
  static const inactivityTimeout = 'inactivityTimeout';
  static const focusTimeout = 'focusTimeout';
  static const preInactivityLogoutCounter = 'preInactivityLogoutCounter';
  static const noOfLogginAttemptAllowed = 'noOfLogginAttemptAllowed';
  static const bruteforceLockOutTime = 'bruteforceLockOutTime';
  static const isNewFirst = 'isNewFirst';
  static const isFlagSecure = 'isFlagSecure';
  static const maxBackupRetryAttempts = 'maxBackupRetryAttempts';
  static const isBiometricAuthEnabled = 'isBiometricAuthEnabled';
  static const biometricAttemptAllTimeCount = 'biometricAttemptAllTimeCount';
  static const isAutoRotate = 'isAutoRotate';
  //massa network based
  static const minimumGassFee = 'minimum-gass-fee';
  static const minimumFee = 'minimum-fee';
  static const slippageAmount = 'slippage-amount'; //slippage in percentage
  static const minimumTransferAmount = 'minimum-transfer-amount';
  static const isMainnet = 'is-mainnet';
  static const wallets = 'secure-wallets';
  static const defaultWalletAddress = 'default-wallet-address';
}

class LocalStorageService {
  bool _isUserActive = false;
  final SharedPreferences sharedPreferences;
  late FlutterSecureStorage _secureStorage;
  LocalStorageService({required this.sharedPreferences}) {
    const androidOptions = AndroidOptions(encryptedSharedPreferences: true);
    const iosOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
    _secureStorage = const FlutterSecureStorage(aOptions: androidOptions, iOptions: iosOptions);
  }

  bool get isFlagSecure => sharedPreferences.getBool(StorageKeys.isFlagSecure) ?? true;

  Future<String> get passphrase async => await getSecureString(StorageKeys.passphraseHash) ?? '';

  Future<void> setPassphrase(String passphrase) async {
    final passphraseHash = sha256.convert(utf8.encode(passphrase)).toString();
    await setSecureString(StorageKeys.passphraseHash, passphraseHash);
  }

  Future<bool> verifyPassphrase(String passphrase) async {
    final passphraseHash1 = sha256.convert(utf8.encode(passphrase)).toString();
    final passphraseHash2 = await getSecureString(StorageKeys.passphraseHash) ?? '';
    if (passphraseHash1 == passphraseHash2) return true;
    return false;
  }

  void setLoginStatus(bool status) => _isUserActive = status;
  bool get isUserActive => _isUserActive;

  bool get isThemeDark => sharedPreferences.getBool(StorageKeys.isThemeDark) ?? true;

  Future<void> setIsThemeDark(bool flag) async => await sharedPreferences.setBool(StorageKeys.isThemeDark, flag);

  Future<void> setIsFlagSecure(bool flag) async => await sharedPreferences.setBool(StorageKeys.isFlagSecure, flag);

  bool get isNewFirst => sharedPreferences.getBool(StorageKeys.isNewFirst) ?? true;

  Future<void> setIsNewFirst(bool flag) async => await sharedPreferences.setBool(StorageKeys.isNewFirst, flag);

  Future<void> setKeyboardIncognito(bool flag) async =>
      await sharedPreferences.setBool(StorageKeys.keyboardIncognito, flag);

  bool get keyboardIncognito => sharedPreferences.getBool(StorageKeys.keyboardIncognito) ?? true;

  int get noOfLogginAttemptAllowed {
    //default: 3 unsuccessful
    return sharedPreferences.getInt(StorageKeys.noOfLogginAttemptAllowed) ?? 4;
  }

  int get bruteforceLockOutTime {
    //default: 30 seconds
    return sharedPreferences.getInt(StorageKeys.bruteforceLockOutTime) ?? 30;
  }

  bool get isInactivityTimeoutOn => sharedPreferences.getBool(StorageKeys.isInactivityTimeoutOn) ?? true;

  Future<void> setIsInactivityTimeoutOn(bool flag) async =>
      await sharedPreferences.setBool(StorageKeys.isInactivityTimeoutOn, flag);

  int get inactivityTimeout {
    //default: 4 minutes
    List<int> choices = [30, 60, 120, 180, 300, 600, 900];
    var index = sharedPreferences.getInt(StorageKeys.inactivityTimeout);
    if (!(index != null && index >= 0 && index < choices.length)) {
      index = 4; // default
    }
    return choices[index];
  }

  int get inactivityTimeoutIndex => sharedPreferences.getInt(StorageKeys.inactivityTimeout) ?? 3;

  Future<void> setInactivityTimeoutIndex({required int index}) async =>
      await sharedPreferences.setInt(StorageKeys.inactivityTimeout, index);

  int get focusTimeout => inactivityTimeout;

  //for logout popup alert. default: 15 seconds
  int get preInactivityLogoutCounter => sharedPreferences.getInt(StorageKeys.preInactivityLogoutCounter) ?? 15;

  bool get isBiometricAuthEnabled => sharedPreferences.getBool(StorageKeys.isBiometricAuthEnabled) ?? false;
  Future<void> setIsBiometricAuthEnabled(bool flag) async =>
      await sharedPreferences.setBool(StorageKeys.isBiometricAuthEnabled, flag);

  int get biometricAttemptAllTimeCount => sharedPreferences.getInt(StorageKeys.biometricAttemptAllTimeCount) ?? 0;

  Future<void> incrementBiometricAttemptAllTimeCount() async =>
      await sharedPreferences.setInt(StorageKeys.biometricAttemptAllTimeCount, biometricAttemptAllTimeCount + 1);

  bool get isAutoRotate => sharedPreferences.getBool(StorageKeys.isAutoRotate) ?? false;

  Future<void> setIsAutoRotate(bool flag) async => await sharedPreferences.setBool(StorageKeys.isAutoRotate, flag);

  /// Clears all app data - use when user forgets passphrase
  Future<void> clearAllData() async {
    await sharedPreferences.clear();
    await _secureStorage.deleteAll();
    _isUserActive = false;
  }

  Future<double> setMinimumGassFee(double minimumGassFee) async {
    if (minimumGassFee < 1.0) {
      minimumGassFee = 1.0;
    }
    sharedPreferences.setDouble(StorageKeys.minimumGassFee, minimumGassFee);
    return minimumGassFee;
  }

  double get minimumGassFee =>
      sharedPreferences.getDouble(StorageKeys.minimumGassFee) ?? 0.01 * 100; //default: 0.01 * 100 = 1.0

  Future<double> setMinimumFee(double minimumFee) async {
    if (minimumFee < 0.01 || minimumFee > 1.0) {
      minimumFee = 0.01;
    }
    sharedPreferences.setDouble(StorageKeys.minimumFee, minimumFee);
    return minimumFee;
  }

  double get minimumFee => sharedPreferences.getDouble(StorageKeys.minimumFee) ?? 0.01; //default: 0.01

  Future<void> setSlipage(double slippage) async => sharedPreferences.setDouble(StorageKeys.slippageAmount, slippage);
  double get slippage => sharedPreferences.getDouble(StorageKeys.slippageAmount) ?? 0.5;

  Future<void> setMinimumTransferAmount(double minimumTransferAmount) async =>
      sharedPreferences.setDouble(StorageKeys.minimumTransferAmount, minimumTransferAmount);
  double get minimumTransferAmount => sharedPreferences.getDouble(StorageKeys.minimumTransferAmount) ?? 0.0;

  Future<void> setNetworkType(bool isMainnet) async => sharedPreferences.setBool(StorageKeys.isMainnet, isMainnet);
  bool get isMainnet => sharedPreferences.getBool(StorageKeys.isMainnet) ?? true;

  Future<void> storeWallets(String encodedWallets) async {
    await setSecureString(StorageKeys.wallets, encodedWallets);
  }

  Future<String> getStoredWallets() async {
    return await getSecureString(StorageKeys.wallets) ?? "";
  }

  Future<String?> getWalletKey(String address) async {
    List<WalletModel> wallets;
    final walletString = await getStoredWallets();
    String encryptedKey = "";
    if (walletString.isNotEmpty) {
      wallets = WalletModel.decode(walletString);
      for (var wallet in wallets) {
        if (wallet.address == address) {
          encryptedKey = wallet.encryptedKey;
          break;
        }
      }
      if (encryptedKey.isNotEmpty) {
        final passphrase = await this.passphrase;
        return decryptAES(encryptedKey, passphrase);
      }
    }
    return encryptedKey;
  }

  Future<void> setDefaultWallet(String address) async {
    return await _secureStorage.write(key: StorageKeys.defaultWalletAddress, value: address);
  }

  Future<String?> getDefaultWallet() async {
    return await _secureStorage.read(key: StorageKeys.defaultWalletAddress);
  }

  Future<String?> getDefaultWalletKey() async {
    final address = await _secureStorage.read(key: StorageKeys.defaultWalletAddress);
    if (address == null) {
      return null;
    }
    return await getWalletKey(address);
  }

  //supporting functions
  //write methods
  Future<void> setSecureBool(String key, bool value) async =>
      await _secureStorage.write(key: key, value: value.toString());
  Future<void> setSecureNum(String key, num value) async =>
      await _secureStorage.write(key: key, value: value.toString());
  Future<void> setSecureString(String key, String value) async => await _secureStorage.write(key: key, value: value);
  Future<void> setSecureBoolList(String key, List<bool> value) async => await _setSecureList<bool>(key, value);
  Future<void> setSecureNumList(String key, List<num> value) async => await _setSecureList<num>(key, value);
  Future<void> setSecureStringList(String key, List<String> value) async => await _setSecureList<String>(key, value);
  Future<void> _setSecureList<T>(String key, List<T> value) async {
    String buffer = json.encode(value);
    return await _secureStorage.write(key: key, value: buffer);
  }

  //read methods
  Future<Set<String>?> getKeys() async => (await _secureStorage.readAll()).keys.toSet();

  Future<bool?> getBool(String key) async {
    String? value = await _secureStorage.read(key: key);
    final result = switch (value) { 'true' => true, 'false' => false, _ => null };
    return result;
  }

  Future<num?> getNum(String key) async {
    String? value = await _secureStorage.read(key: key);
    final result = num.tryParse(value ?? '');
    return result;
  }

  Future<String?> getSecureString(String key) async => await _secureStorage.read(key: key);

  Future<List<bool>?> getBoolList(String key) async {
    String? value = await _secureStorage.read(key: key);
    final decodedValue = json.decode(value!);

    List<bool> result = decodedValue.map((i) {
      return switch (i) { 'true' => true, _ => false };
    }).toList();
    return result;
  }

  Future<List<num>?> getNumList(String key) async {
    String? value = await _secureStorage.read(key: key);
    final decodedValue = json.decode(value!);

    List<num> result = decodedValue.map((i) {
      return num.tryParse(i ?? '');
    }).toList();
    return result;
  }

  Future<List<String>?> getStringList(String key) async {
    String? value = await _secureStorage.read(key: key);
    final decodedValue = json.decode(value!);
    List<String> result = decodedValue.map((i) {
      return i;
    }).toList();
    return result;
  }

  Future<void> delete(String key) async {
    return _secureStorage.delete(key: key);
  }
}

class AsyncInit {
  final Ref ref;
  late final SharedPreferences sharedPreferences;

  AsyncInit({required this.ref});

//put here all functions to be initialised before we start using the provider
  Future<void> init() async {
    await Future.wait([
      SharedPreferences.getInstance().then((value) {
        sharedPreferences = value;
      }),
    ]);
  }
}
