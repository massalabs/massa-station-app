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
    final pass = ref.read(localStorageServiceProvider).passphrase;
    return FutureBuilder(
        future: pass,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isNotEmpty) {
              return LoginView(
                isKeyboardFocused: isKeyboardFocused,
              );
            } else {
              return SetPassphraseView(
                isKeyboardFocused: isKeyboardFocused,
              );
            }
          }
          return const CircularProgressIndicator();
        });
  }
}
