class DomainDetails {
  String? targetAddress;
  String? tokenId;
  String? ownerAddress;

  DomainDetails({targetAddress, tokenId, ownerAddress});

  DomainDetails.decode(Map<String, dynamic> json) {
    targetAddress = json['target_address'];
    tokenId = json['tokenId'];
    ownerAddress = json['owner_address'];
  }

  Map<String, dynamic> encode() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['target_address'] = targetAddress;
    data['tokenId'] = tokenId;
    data['owner_address'] = ownerAddress;
    return data;
  }
}
