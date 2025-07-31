/// OperationTypes defines transaction, CallSC, BuyRoll, and SellRoll operations
class OperationTypeEntity {
  TransactionOperationEntity? transaction;
  ExecuteSCOperationEntity? executeSC;
  CallSCOperationEntity? callSC;
  BuyRollOperationEntity? buyRoll;
  SellRollOperationEntity? sellRoll;

  OperationTypeEntity({this.transaction, this.executeSC, this.buyRoll, this.sellRoll});
}

/// Transaction operation class
class TransactionOperationEntity {
  late final String recipientAddress;
  late final String amount;
  TransactionOperationEntity({required this.recipientAddress, required this.amount});
}

/// ExecuteSCOperationEntity
class ExecuteSCOperationEntity {}

class CallSCOperationEntity {
  late String targetAddr;
  late int coins;
  late String param;
  late int maxGas;
  late String targetFunc;

  CallSCOperationEntity({
    required this.targetAddr,
    required this.coins,
    required this.param,
    required this.maxGas,
    required this.targetFunc,
  });
}

/// BuyRoll operation class
class BuyRollOperationEntity {
  BuyRollOperationEntity({required this.rollCount});
  late final int rollCount;
}

/// SellRoll operation class
class SellRollOperationEntity {
  SellRollOperationEntity({required this.rollCount});
  late final int rollCount;
}
