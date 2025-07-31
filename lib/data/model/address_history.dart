import 'package:mug/data/model/transaction_history.dart';

class AddressTransactionHistory {
  List<String>? operationsNodes;
  List<TransactionHistory>? operationsCreated;
  List<TransactionHistory>? operationsReceived;
  List<TransactionHistory>? combinedHistory;
  String? nextCursorCreated;
  String? nextCursorReceived;

  AddressTransactionHistory(
      {this.operationsNodes,
      this.operationsCreated,
      this.operationsReceived,
      this.nextCursorCreated,
      this.nextCursorReceived});

  AddressTransactionHistory.decode(Map<String, dynamic> json) {
    if (json['operationsNodes'] != null) {
      operationsNodes = <String>[];
      json['operationsNodes'].forEach((v) {
        operationsNodes!.add(v);
      });
    }
    if (json['operationsCreated'] != null) {
      operationsCreated = <TransactionHistory>[];
      json['operationsCreated'].forEach((v) {
        operationsCreated!.add(TransactionHistory.decode(v));
      });
    }
    if (json['operationsReceived'] != null) {
      operationsReceived = <TransactionHistory>[];
      json['operationsReceived'].forEach((v) {
        operationsReceived!.add(TransactionHistory.decode(v));
      });
    }
    nextCursorCreated = json['nextCursorCreated'];
    nextCursorReceived = json['nextCursorReceived'];
  }

  Map<String, dynamic> encode() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (operationsNodes != null) {
      data['operationsNodes'] = operationsNodes!.map((v) => v).toList();
    }
    if (operationsCreated != null) {
      data['operationsCreated'] = operationsCreated!.map((v) => v.encode()).toList();
    }
    if (operationsReceived != null) {
      data['operationsReceived'] = operationsReceived!.map((v) => v.encode()).toList();
    }
    data['nextCursorCreated'] = nextCursorCreated;
    data['nextCursorReceived'] = nextCursorReceived;
    return data;
  }
}
