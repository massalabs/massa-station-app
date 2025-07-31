import 'package:mug/domain/entity/transaction_entity.dart';

class TransactionHistory {
  List<TransactionEntity>? operationsCreated;
  List<TransactionEntity>? operationsReceived;
  String? nextCursorCreated;
  String? nextCursorReceived;

  TransactionHistory(
      {this.operationsCreated, this.operationsReceived, this.nextCursorCreated, this.nextCursorReceived});
}
