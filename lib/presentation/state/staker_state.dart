// Project imports:
import 'package:mug/domain/entity/staker_entity.dart';

sealed class StakerState {}

final class StakerInitial extends StakerState {}

final class StakerLoading extends StakerState {}

final class StakersSuccess extends StakerState {
  final StakersEntity stakers;
  StakersSuccess({required this.stakers});
}

final class StakerFailure extends StakerState {
  final String message;
  StakerFailure({required this.message});
}
