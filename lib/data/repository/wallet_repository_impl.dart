// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/data/data_source/network/wallet_network_data_source_impl.dart';
import 'package:mug/data/data_source/wallet_data_source.dart';
import 'package:mug/domain/entity/address_entity.dart';
import 'package:mug/domain/repository/wallet_repository.dart';
import 'package:mug/utils/exception_handling.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletDataSource dataSource;

  WalletRepositoryImpl({
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
  Future<Result<List<AddressEntity>, Exception>> getAddresses(List<String> address) async {
    try {
      return await dataSource.getAddresses(address);
    } on Exception catch (error) {
      return Failure(exception: error);
    }
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(dataSource: ref.watch(walletNetworkDatasourceProvider));
});
