// Project imports:
import 'package:mug/domain/entity/entity.dart';

sealed class DomainState {}

final class DomainInitial extends DomainState {}

final class DomainLoading extends DomainState {}

final class DomainSuccess extends DomainState {
  final DomainEntity domainEntity;
  DomainSuccess({required this.domainEntity});
}

final class DomainFailure extends DomainState {
  final String message;
  DomainFailure({required this.message});
}
