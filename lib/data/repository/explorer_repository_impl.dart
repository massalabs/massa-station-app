// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/data/data_source/explorer_data_source.dart';
import 'package:mug/data/data_source/network/explorer_network_data_source_impl.dart';
import 'package:mug/domain/entity/entity.dart';
import 'package:mug/domain/repository/explorer_repository.dart';
// ignore: unused_import
import 'package:mug/presentation/state/block_state.dart';
import 'package:mug/utils/exception_handling.dart';

class ExplorerRepositoryImpl implements ExplorerRepository {
  final ExplorerDataSource dataSource;

  ExplorerRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<Result<AddressEntity, Exception>> getAddress(String address) async {
    try {
      return await dataSource.getAddress(address);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<BlockEntity, Exception>> getBlock(String hash) async {
    try {
      return await dataSource.getBlock(hash);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<StakersEntity, Exception>> getStakers(int pageNumber) async {
    try {
      return await dataSource.getStakers(pageNumber);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<OperationEntity, Exception>> getOperation(String hash) async {
    try {
      return await dataSource.getOperation(hash);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<DomainEntity, Exception>> getDomain(String domainName) async {
    try {
      return await dataSource.getDomain(domainName);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }

  @override
  Future<Result<(String, bool), Exception>> buyDomain(String domainName, double domainPrice) async {
    try {
      return await dataSource.buyDomain(domainName, domainPrice);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final explorerRepositoryProvider = Provider<ExplorerRepository>((ref) {
  return ExplorerRepositoryImpl(dataSource: ref.watch(explorerNetworkDatasourceProvider));
});
