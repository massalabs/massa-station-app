class QuoterEntity {
  final List<dynamic> router;
  final List<dynamic> pair;
  final List<dynamic> binSteps;
  final List<dynamic> amounts;
  final List<dynamic> amountsWithoutSlipage;
  final List<dynamic> fees;

  const QuoterEntity({
    required this.router,
    required this.pair,
    required this.binSteps,
    required this.amounts,
    required this.amountsWithoutSlipage,
    required this.fees,
  });
}
