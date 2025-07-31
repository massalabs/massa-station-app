// This file is part of the Massa Wallet project.
// The Massa Wallet project is licensed under the GNU General Public License v3.0.
//
// This file contains the environment variables used in the application.
// These variables are used to configure the gRPC host, gRPC port, JSON-RPC host,
// JSON-RPC version, and the explorer host.
// It also includes a private key for testing purposes only.
// The private key should be kept private and never used in production.
// The corresponding public key and address are also provided for reference.
// The private key is used for testing only and should never be used in production.
// The corresponding public key and address are also provided for reference.
// The private key is used for testing only and should never be used in production.

class Env {
  static const grpcHost = String.fromEnvironment(
    'grpc_host',
    defaultValue: 'buildnet.massa.net',
  );
  static const grpcPort = int.fromEnvironment(
    'grpc_port',
    defaultValue: 33037,
  );

  static const jrpcHost = String.fromEnvironment(
    'jrpc_host',
    defaultValue: 'mainnet.massa.net',
  );
  static const jrpcVersion = String.fromEnvironment(
    'jrpc_port',
    defaultValue: "api/v2",
  );

  static const explorerHost = String.fromEnvironment(
    'explorer_host',
    defaultValue: "explorer-api.massa.net",
  );

  /// privateKey should be kept private. But this key is here for experimenting and never use it.
  /// its corresponding public key: P16CaSWoXu5A3AVTynHZH4BP8rkd1GNuSvwxMwWpJZwNcYmamww
  /// its correspoding address:    AU1y3oYTgK8RGzLWFVAGL3JxHLdTVKxBPHrwbo2Kj8a2CSbeMug
  static const privateKey = String.fromEnvironment(
    'privateKey',
    defaultValue:
        "S1R3W8t9tRBxxRsULe2cLJXX1moAragCzKh8gVxB8PBLJdA4vCD", //this private key is used for testing only. Never use it as it is publicly avaiable.
  );
}
