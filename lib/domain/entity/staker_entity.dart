class StakerEntity {
  final String address;
  final int rank;
  final int rolls;
  final double ownershipPercentage;
  final double estimatedDailyReward;

  const StakerEntity(
      {required this.address,
      required this.rank,
      required this.rolls,
      required this.ownershipPercentage,
      required this.estimatedDailyReward});
}

class StakersEntity {
  final int stakerNumbers;
  final int totalRolls;
  final List<StakerEntity> stakers;

  const StakersEntity({
    required this.stakerNumbers,
    required this.totalRolls,
    required this.stakers,
  });
}
