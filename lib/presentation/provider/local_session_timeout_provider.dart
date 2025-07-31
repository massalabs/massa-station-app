// Dart imports:
import 'dart:async';
import 'dart:developer';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

// Project imports:

class LocalSessionTimeoutProvider extends StateNotifier<StreamController<SessionState>> {
  LocalSessionTimeoutProvider() : super(StreamController<SessionState>());

  StreamController<SessionState> getSession() {
    _debug();
    return state;
  }

  void _debug() {
    log('Passphrase: $state');
  }
}

final localSessionTimeoutProvider =
    StateNotifierProvider<LocalSessionTimeoutProvider, StreamController<SessionState>>((ref) {
  print("local session provider initalised...");
  return LocalSessionTimeoutProvider();
});
