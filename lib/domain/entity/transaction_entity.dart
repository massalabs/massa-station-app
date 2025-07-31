class TransactionEntity {
  String? hash;
  String? blockTime;
  String? status;
  String? type;
  String? from;
  String? to;
  String? value;
  String? transactionFee;
  bool? opExecStatus;

  TransactionEntity(
      {this.hash,
      this.blockTime,
      this.status,
      this.type,
      this.from,
      this.to,
      this.value,
      this.transactionFee,
      this.opExecStatus});
}
