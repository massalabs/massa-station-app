// This file contains the implementation of the JrpcService interface.
// It provides methods for making JSON-RPC calls to the Massa network.
// The JrpcServiceImpl class implements the JrpcService interface and provides
// methods for getting stakers, addresses, and a list of addresses.
// The class uses the JsonrpcPublicApi to interact with the Massa network.
// It also includes error handling for network requests and response parsing.
// The JrpcServiceImpl class is a singleton and is initialized with the JSON-RPC host and version.

// The class is part of the Massa Wallet project and is licensed under the MIT License.
import 'package:massa/massa.dart';
import 'package:mug/env/env.dart';

abstract interface class JrpcService {
  Future<Stakers> getStakers();
  Future<Address?> getAddress(String address);
  Future<List<Address>?> getAddresses(List<String> addresses);
}

class JrpcServiceImpl implements JrpcService {
  final _jrpc = JsonrpcPublicApi(Uri.https(Env.jrpcHost, Env.jrpcVersion));

  @override
  Future<Stakers> getStakers() async {
    try {
      return await _jrpc.getStakers();
    } catch (error) {
      throw Exception(error);
    }
  }

  @override
  Future<Address?> getAddress(String address) async {
    try {
      var response = await _jrpc.getAddresses([address]);
      if (response!.isNotEmpty) {
        return response[0];
      } else {
        return null;
      }
    } catch (error) {
      throw Exception(error);
    }
  }

  @override
  Future<List<Address>?> getAddresses(List<String> addresses) async {
    try {
      var response = await _jrpc.getAddresses(addresses);
      if (response!.isNotEmpty) {
        return response;
      } else {
        return null;
      }
    } catch (error) {
      throw Exception(error);
    }
  }
}
