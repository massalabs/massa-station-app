// Project imports:

// Project imports:
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/utils/exception_handling.dart';

abstract interface class ExplorerRepository {
  Future<Result<AddressEntity, Exception>> getAddress(String address);
  Future<Result<BlockEntity, Exception>> getBlock(String hash);
  Future<Result<OperationEntity, Exception>> getOperation(String hash);
  Future<Result<DomainEntity, Exception>> getDomain(String domainName);
  Future<Result<(String, bool), Exception>> buyDomain(String domainName, double domainPrice);
  Future<Result<StakersEntity, Exception>> getStakers(int pageNumber);
}
