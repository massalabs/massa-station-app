class ExplorerStakers {
  int? totalStakers; //use this to establish number of pages. Each page has 64 entries.
  List<ExplorerStaker>? stakers;
  int? totalRolls;

  ExplorerStakers({this.totalStakers, this.stakers, this.totalRolls});

  ExplorerStakers.decode(Map<String, dynamic> json) {
    totalStakers = (json['total_stakers'] is String) ? int.parse(json['total_stakers']) : json['total_stakers'];
    if (json['stakers'] != null) {
      stakers = <ExplorerStaker>[];
      json['stakers'].forEach((v) {
        stakers!.add(ExplorerStaker.decode(v));
      });
    }
    totalRolls = (json['total_rolls'] is String) ? int.parse(json['total_rolls']) : json['total_rolls'];
  }

  Map<String, dynamic> encode() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_stakers'] = totalStakers;
    if (stakers != null) {
      data['stakers'] = stakers!.map((v) => v.encode()).toList();
    }
    data['total_rolls'] = totalRolls;
    return data;
  }
}

class ExplorerStaker {
  String? hash;
  int? producedBlocks;
  int? rollsCount;
  String? rollsCountValue;
  double? percentageOfShare;
  String? deferredCredits;

  ExplorerStaker(
      {this.hash,
      this.producedBlocks,
      this.rollsCount,
      this.rollsCountValue,
      this.percentageOfShare,
      this.deferredCredits});

  ExplorerStaker.decode(Map<String, dynamic> json) {
    hash = json['hash'];
    producedBlocks = (json['produced_blocks'] is String) ? int.parse(json['produced_blocks']) : json['produced_blocks'];
    rollsCount = (json['rolls_count'] is String) ? int.parse(json['rolls_count']) : json['rolls_count'];
    rollsCountValue =
        (json['rolls_count_value'] is String) ? json['rolls_count_value'] : int.parse(json['rolls_count_value']);
    percentageOfShare =
        (json['percentage_of_share'] is int) ? (json['percentage_of_share']).toDouble() : json['percentage_of_share'];
    //deferredCredits = json['deferred_credits'];
  }

  Map<String, dynamic> encode() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hash'] = hash;
    data['produced_blocks'] = producedBlocks;
    data['rolls_count'] = rollsCount;
    data['rolls_count_value'] = rollsCountValue;
    data['percentage_of_share'] = percentageOfShare;
    // data['deferred_credits'] = deferredCredits;
    return data;
  }
}
