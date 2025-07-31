class TransferEntity {
  final String? sendingAddress;
  final String? recipientAddress;
  final double? amount;
  final bool? isTransfered;
  final String? operationID;

  TransferEntity({
    this.sendingAddress,
    this.recipientAddress,
    this.amount,
    this.isTransfered,
    this.operationID,
  });

  // Create a copyWith method to update parts of the state
  TransferEntity copyWith({
    String? sendingAddress,
    String? recipientAddress,
    double? amount,
    bool? showNotification,
    String? notificationMessage,
  }) {
    return TransferEntity(
      sendingAddress: sendingAddress ?? this.sendingAddress,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      amount: amount ?? this.amount,
      isTransfered: isTransfered ?? this.isTransfered,
      operationID: operationID ?? this.operationID,
    );
  }
}
