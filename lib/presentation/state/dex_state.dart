// Project imports:
import 'package:mug/domain/entity/swap_entity.dart';

sealed class DexState {}

final class DexInitial extends DexState {}

final class DexLoading extends DexState {}

final class DexSuccess extends DexState {
  final SwapEntity swapEntity;

  DexSuccess({required this.swapEntity});
}

final class DexFailure extends DexState {
  final String message;
  DexFailure({required this.message});
}
