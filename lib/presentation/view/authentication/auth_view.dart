// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/presentation/view/authentication/login_view.dart';
import 'package:mug/presentation/view/authentication/set_passphrase_view.dart';
import 'package:mug/service/provider.dart';

class AuthView extends ConsumerWidget {
  final bool? isKeyboardFocused;
  const AuthView({super.key, this.isKeyboardFocused});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if passphrase verification is set up by checking for verification hash
    final verificationCheck = ref.read(localStorageServiceProvider).getSecureString('passphrase_verify_hash');
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
        });
  }
}
