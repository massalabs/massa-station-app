// This file contains the ExplorerApi class which is used to interact with the Massa Explorer API.
// It provides methods to fetch address details, block details, operation details,
// stakers information, address transaction history, and domain details.
// The class uses the http package to make network requests and handle responses.
// It also includes error handling for network requests and response parsing.
// The ExplorerApi class is a singleton and is initialized with a base URI.
//
// It is part of the Massa Wallet project and is licensed under the MIT License.

import 'dart:convert';

import 'package:massa/massa.dart';
import 'package:mug/data/model/block.dart';
import 'package:mug/data/model/domain.dart';
import 'package:mug/data/model/address_history.dart';
import 'package:mug/data/model/stakers.dart';
import 'package:mug/env/env.dart';
import 'package:http/http.dart' as http;

class ExplorerApi {
  late Uri baseUri;
  late Client client;
  //Singleton class
  static final ExplorerApi _instance = ExplorerApi.internal();
  ExplorerApi.internal();
  factory ExplorerApi(Uri uri) {
    _instance.baseUri = uri;
    _instance.client = Client(_instance.baseUri);
    return _instance;
  }

  /// Returns details of passed addresses mainly to check when a specific address is selected to stake
  /// Need to provide at least one valid address
  Future<Address?> getAddress(String address) async {
    final path = 'address/$address';
    try {
      var response = await client.get(path);
      var data = Map<String, dynamic>.from(response);
      return Address.decode(data);
    } catch (e) {
      return null;
    }
  }

  /// Gets details of a blocks given block hashes
  /// Need to provide at least one valid block id
  Future<ExplorerBlock?> getBlock(String block) async {
    final path = 'block/$block';
    try {
      var response = await client.get(path);
      var data = Map<String, dynamic>.from(response['block']);
      return ExplorerBlock.decode(data);
    } catch (e) {
      return null;
    }
  }

  /// Gets operation details given the operation hashes
  /// Need to provide at least one valid operation id
  Future<Operation?> getOperation(String operation) async {
    final path = 'operation/$operation';
    try {
      var response = await client.get(path);
      print('operation response: $response');
      var data = Map<String, dynamic>.from(response);
      return Operation.decode(data);
    } catch (e) {
      return null;
    }
  }

  /// Returns the active stakers and their roll counts for the current cycle.
  Future<ExplorerStakers?> getStakers(int pageNumber) async {
    const path = 'stakers';
    final params = {'page': pageNumber.toString()};

    try {
      var response = await client.get(path, params: params);
      //print('stakers: $response');
      var data = Map<String, dynamic>.from(response);
      return ExplorerStakers.decode(data);
    } catch (e) {
      print("error: ${e.toString()}");
      return null;
    }
  }

  /// Returns the active stakers and their roll counts for the current cycle.
  Future<AddressTransactionHistory?> getAddressTransactionHistory(String address, bool from, bool to,
      {String? cursorCreated, String? cursorReceived}) async {
    final path = 'address/$address/operations';
    final Map<String, dynamic> params = {
      'from': '$from',
      'to': "$to",
    };

    if (cursorCreated != "") {
      params['cursorCreated'] = cursorCreated;
    }
    if (cursorReceived != "") {
      params['cursorReceived'] = cursorReceived;
    }

    try {
      var response = await client.get(path, params: params);
      //print('stakers: $response');
      var data = Map<String, dynamic>.from(response);
      return AddressTransactionHistory.decode(data);
    } catch (e) {
      return null;
    }
  }

  /// Returns the list of domains associated with the given addres
  Future<List<String>?> getAddressDomains(String address) async {
    const path = 'dns/addresses/target';
    final Map<String, dynamic> params = {
      'addresses[]': address,
    };

    try {
      var response = await client.get(path, params: params);
      return List<String>.from(response[address]);
    } catch (e) {
      return null;
    }
  }

  /// Returns the domain details
  Future<DomainDetails?> getDomainDetails(String domain) async {
    domain = domain.trim();
    domain = domain.substring(0, domain.length - 6); //remove .massa part of the string
    const path = 'dns/info';

    final url = Uri.parse("https://${Env.explorerHost}/$path");
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode([domain]);

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        var data = Map<String, dynamic>.from(json.decode(response.body.toString())[domain]);
        return DomainDetails.decode(data);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
