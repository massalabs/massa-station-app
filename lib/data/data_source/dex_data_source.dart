// Project imports:

// Project imports:
import 'package:dusa/dusa.dart';
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/utils/exception_handling.dart';

abstract interface class DexDataSource {
  Future<Result<QuoterEntity, Exception>> findBestPathFromAmountIn(
      String accountAddress, TokenName token1, TokenName token2, double amount);
  Future<Result<QuoterEntity, Exception>> findBestPathFromAmountOut(
      String accountAddress, TokenName token1, TokenName token2, double amount);
  Future<Result<AddressEntity, Exception>> getMASBalance(
    String accountAddress,
  );
  Future<Result<BigInt, Exception>> getTokenBalance(String accountAddress, TokenName tokenType);
  Future<Result<(String, bool), Exception>> swapToken(String accountAddress, SwapEntity data);
}
