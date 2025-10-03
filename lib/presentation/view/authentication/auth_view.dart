// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/presentation/view/authentication/login_view.dart';
import 'package:mug/presentation/view/authentication/select_auth_mode_view.dart';
import 'package:mug/presentation/view/authentication/set_passphrase_view.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/service/provider.dart';

class AuthView extends ConsumerWidget {
  final bool? isKeyboardFocused;
  const AuthView({super.key, this.isKeyboardFocused});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(localStorageServiceProvider);

    // First, check if authentication mode is set
    if (!storage.isAuthenticationModeSet) {
      // Check if biometrics are available
      return FutureBuilder<bool>(
        future: storage.canUseBiometrics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final hasBiometrics = snapshot.data ?? false;

          if (hasBiometrics) {
            // Show mode selection dialog
            return const SelectAuthModeView();
          } else {
            // No biometrics, go directly to passphrase setup
            return SetPassphraseView(
              isKeyboardFocused: isKeyboardFocused,
            );
          }
        },
      );
    }

    // Authentication mode is set, check which mode and if already set up
    final mode = storage.authenticationMode;

    if (mode == AuthenticationMode.biometricOnly) {
      // Biometric Only mode - check if key exists
      return FutureBuilder<bool>(
        future: storage.hasBiometricKey(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            // Already set up, show login
            return LoginView(
              isKeyboardFocused: isKeyboardFocused,
            );
          } else {
            // Not set up yet (shouldn't happen), show mode selection
            return const SelectAuthModeView();
          }
        },
      );
    } else {
      // Passphrase mode - check if passphrase is set
      final verificationCheck = storage.getSecureString('passphrase_verify_hash');
      return FutureBuilder<String?>(
        future: verificationCheck,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            // On error, assume first time setup
            return SetPassphraseView(
              isKeyboardFocused: isKeyboardFocused,
            );
          }

          // Check the actual data value (null or empty = not set up yet)
          if (snapshot.connectionState == ConnectionState.done) {
            final verificationSalt = snapshot.data;
            if (verificationSalt != null && verificationSalt.isNotEmpty) {
              // Passphrase already set up, show login
              return LoginView(
                isKeyboardFocused: isKeyboardFocused,
              );
            } else {
              // First time setup, show passphrase creation
              return SetPassphraseView(
                isKeyboardFocused: isKeyboardFocused,
              );
            }
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
  }
}
