// Project imports:

import 'package:mug/domain/entity/block_entity.dart';

sealed class BlockState {}

final class BlockInitial extends BlockState {}

final class BlockLoading extends BlockState {}

final class BlockSuccess extends BlockState {
  final BlockEntity blockEntity;
  BlockSuccess({required this.blockEntity});
}

final class BlockFailure extends BlockState {
  final String message;
  BlockFailure({required this.message});
}
