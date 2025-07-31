// This file contains the AddressEntity class, which represents an address in the Tezos blockchain.
// It includes properties such as address, thread, final balance, candidate balance,
// final rolls, candidate rolls, active roles, created blocks, created endorsements,
// transaction history, and token balances.
// The class also includes a copyWith method for creating a new instance with modified properties.

// It is part of the Massa Wallet project and is licensed under the MIT License.

import 'package:dusa/dusa.dart';
import 'package:mug/data/model/address_history.dart';

class TokenBalance {
  final TokenName name;
  final double balance;
  final String iconPath;
  const TokenBalance({required this.name, required this.balance, required this.iconPath});
}

class AddressEntity {
  final String address;
  final int thread;
  final double finalBalance;
  final double candidateBalance;
  final int finalRolls;
  final int candidateRolls;
  final int activeRoles;
  final int createdBlocks;
  final int createdEndorsements;
  final AddressTransactionHistory? transactionHistory;
  final List<TokenBalance>? tokenBalances;

  const AddressEntity({
    required this.address,
    required this.thread,
    required this.finalBalance,
    required this.candidateBalance,
    required this.finalRolls,
    required this.candidateRolls,
    required this.activeRoles,
    required this.createdBlocks,
    required this.createdEndorsements,
    this.transactionHistory,
    this.tokenBalances,
  });

  AddressEntity copyWith({
    String? address,
    int? thread,
    double? finalBalance,
    double? candidateBalance,
    int? finalRolls,
    int? candidateRolls,
    int? activeRoles,
    int? createdBlocks,
    int? createdEndorsements,
    AddressTransactionHistory? transactionHistory,
    List<TokenBalance>? tokenBalances,
  }) {
    return AddressEntity(
        address: address ?? this.address,
        thread: thread ?? this.thread,
        finalBalance: finalBalance ?? this.finalBalance,
        candidateBalance: candidateBalance ?? this.candidateBalance,
        finalRolls: finalRolls ?? this.finalRolls,
        candidateRolls: candidateRolls ?? this.candidateRolls,
        activeRoles: activeRoles ?? this.activeRoles,
        createdBlocks: createdBlocks ?? this.createdBlocks,
        createdEndorsements: createdEndorsements ?? this.createdEndorsements,
        transactionHistory: transactionHistory ?? this.transactionHistory,
        tokenBalances: tokenBalances ?? this.tokenBalances);
  }
}
