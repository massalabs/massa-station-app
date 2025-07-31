import 'package:mug/domain/entity/operation_type_entity.dart';

class OperationEntity {
  OperationEntity({
    this.id,
    this.inPool,
    this.inBlocks,
    this.isFinal,
    this.thread,
    this.opExecutionStatus,
    required this.operation,
  });
  String? id;
  bool? inPool;
  List<String>? inBlocks;
  bool? isFinal;
  int? thread;
  bool? opExecutionStatus;
  int? timestamp;
  OperationEntityData operation;
}

/// OperationEntityData
class OperationEntityData {
  late final String contentCreatorAddress;
  late final String contentCreatorPubKey;
  late final String signature;
  late final OperationEntityContent content;

  OperationEntityData({
    required this.contentCreatorAddress,
    required this.contentCreatorPubKey,
    required this.signature,
    required this.content,
  });
}

/// Operation contents
class OperationEntityContent {
  late final String fee;
  late final int expirePeriod;
  late final OperationTypeEntity op;
  OperationEntityContent({required this.fee, required this.expirePeriod, required this.op});
}
