class TransactionHistory {
  String? hash;
  String? blockTime;
  String? status;
  String? type;
  String? from;
  String? to;
  String? value;
  String? transactionFee;
  bool? opExecStatus;

  TransactionHistory(
      {this.hash,
      this.blockTime,
      this.status,
      this.type,
      this.from,
      this.to,
      this.value,
      this.transactionFee,
      this.opExecStatus});

  TransactionHistory.decode(Map<String, dynamic> json) {
    hash = json['hash'];
    blockTime = json['block_time'];
    status = json['status'];
    type = json['type'];
    from = json['from'];
    to = json['to'];
    value = json['value'];
    transactionFee = json['transaction_fee'];
    opExecStatus = json['op_exec_status'];
  }

  Map<String, dynamic> encode() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hash'] = hash;
    data['block_time'] = blockTime;
    data['status'] = status;
    data['type'] = type;
    data['from'] = from;
    data['to'] = to;
    data['value'] = value;
    data['transaction_fee'] = transactionFee;
    data['op_exec_status'] = opExecStatus;
    return data;
  }
}
