import 'package:mug/data/model/transaction_history.dart';

class ExplorerBlock {
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
  List<TransactionHistory>? latestOps;

  ExplorerBlock(
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

  ExplorerBlock.decode(Map<String, dynamic> json) {
    hash = json['hash'];
    isFinal = json['is_final'];
    blockTime = json['block_time'];
    creatorAddress = json['creator_address'];
    operationCount = json['operation_count'];
    endorsements = json['endorsements'];
    parents = json['parents'].cast<String>();
    isInBlockclique = json['is_in_blockclique'];
    blockReward = json['block_reward'];
    blockSize = json['block_size'];
    thread = json['thread'];
    period = json['period'];
    signature = json['signature'];
    creatorPublicKey = json['creator_public_key'];
    if (json['latest_ops'] != null) {
      latestOps = <TransactionHistory>[];
      json['latest_ops'].forEach((v) {
        latestOps!.add(TransactionHistory.decode(v));
      });
    }
  }

  Map<String, dynamic> encode() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hash'] = hash;
    data['is_final'] = isFinal;
    data['block_time'] = blockTime;
    data['creator_address'] = creatorAddress;
    data['operation_count'] = operationCount;
    data['endorsements'] = endorsements;
    data['parents'] = parents;
    data['is_in_blockclique'] = isInBlockclique;
    data['block_reward'] = blockReward;
    data['block_size'] = blockSize;
    data['thread'] = thread;
    data['period'] = period;
    data['signature'] = signature;
    data['creator_public_key'] = creatorPublicKey;
    if (latestOps != null) {
      data['latest_ops'] = latestOps!.map((v) => v.encode()).toList();
    }
    return data;
  }
}
