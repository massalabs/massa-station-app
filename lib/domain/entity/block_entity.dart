// This file defines the BlockEntity class, which represents a block in a blockchain.
// It includes properties such as hash, isFinal, blockTime, creatorAddress,
// operationCount, endorsements, parents, isInBlockclique, blockReward,
// blockSize, thread, period, signature, creatorPublicKey, and latestOps.
// The class also includes a constructor to initialize these properties.
// The class is used to represent a block in the blockchain and its associated data.
//
// It is part of the Massa Wallet project and is licensed under the MIT License.

import 'package:mug/domain/entity/transaction_entity.dart';

class BlockEntity {
  String? hash;
  bool? isFinal;
  String? blockTime;
  String? creatorAddress;
  int? operationCount;
  int? endorsements;
  List<String>? parents;
  bool? isInBlockclique;
  int? blockReward;
  int? blockSize;
  int? thread;
  int? period;
  String? signature;
  String? creatorPublicKey;
  List<TransactionEntity>? latestOps;

  BlockEntity(
      {this.hash,
      this.isFinal,
      this.blockTime,
      this.creatorAddress,
      this.operationCount,
      this.endorsements,
      this.parents,
      this.isInBlockclique,
      this.blockReward,
      this.blockSize,
      this.thread,
      this.period,
      this.signature,
      this.creatorPublicKey,
      this.latestOps});
}
