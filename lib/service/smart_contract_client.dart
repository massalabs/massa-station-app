import 'package:dusa/service/grpc_service.dart';
import 'package:massa/massa.dart';

class SmartContractService {
  final bool isBuildnet;
  late Account account;
  late GrpcServiceImpl client;
  //final LocalStorageService localStorageService;

  SmartContractService({required this.account, required this.isBuildnet}) {
    client = GrpcServiceImpl(account: account, isBuildnet: isBuildnet);
  }
  void updateAccount(String privateKey) async {
    final account = await Wallet()
        .addAccountFromSecretKey(privateKey, AddressType.user, isBuildnet ? NetworkType.BUILDNET : NetworkType.MAINNET);
    client.account = account;
  }
}
