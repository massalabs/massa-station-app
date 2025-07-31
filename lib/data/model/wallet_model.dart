// Project imports:
import 'dart:convert';

import 'package:mug/domain/entity/address_entity.dart';
import 'package:mug/domain/entity/wallet_entity.dart';

class WalletData {
  int rolls = 0;
  double finalBalance = 0.0;
  List<WalletModel> wallets = [];
}

class WalletModel extends WalletEntity {
  @override
  final String address;
  @override
  final String encryptedKey;
  @override
  AddressEntity? addressInformation;
  @override
  final String? name; //account name

  WalletModel({required this.address, required this.encryptedKey, this.addressInformation, this.name})
      : super(address: address, encryptedKey: encryptedKey);

  factory WalletModel.fromJson(Map<String, dynamic> data) {
    return WalletModel(
      address: data['address'] as String,
      encryptedKey: data['encrypted_key'] as String,
      name: data['name'] ?? (data['address'] as String).substring((data['address'] as String).length - 4),
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['encrypted_key'] = encryptedKey;
    data['name'] = name;
    return data;
  }

  WalletModel copyWith({
    String? address,
    String? encryptedKey,
    String? name,
  }) {
    return WalletModel(
      address: address ?? this.address,
      encryptedKey: encryptedKey ?? this.encryptedKey,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WalletModel && other.address == address && other.encryptedKey == encryptedKey;
  }

  @override
  int get hashCode {
    return address.hashCode ^ encryptedKey.hashCode;
  }

  static String encode(List<WalletModel> wallets) => json.encode(
        wallets.map<Map<String, dynamic>>((wallet) => wallet.toMap()).toList(),
      );

  static List<WalletModel> decode(String walletString) =>
      (json.decode(walletString) as List<dynamic>).map<WalletModel>((item) => WalletModel.fromJson(item)).toList();
}
