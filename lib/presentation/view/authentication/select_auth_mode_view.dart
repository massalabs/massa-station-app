// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/service/provider.dart';
import 'package:mug/service/local_storage_service.dart';
import 'package:mug/routes/routes.dart';

class SelectAuthModeView extends ConsumerWidget {
  const SelectAuthModeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/icons/massa_station_full.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.security,
              size: 60,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose\nAuthentication Method',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Biometric Option
            _buildModeCard(
              context: context,
              icon: Icons.fingerprint,
              title: 'Biometric',
              subtitle: '',
              description: '• Random master key securely stored\n• Quick fingerprint/face unlock\n• Device PIN as fallback\n• Most convenient\n• But someone may steal your finger/face',
              onTap: () => _selectBiometricMode(context, ref),
            ),

            const SizedBox(height: 16),

            // Passphrase Option
            _buildModeCard(
              context: context,
              icon: Icons.password,
              title: 'Passphrase',
              subtitle: '',
              description: '• You choose a passphrase\n• Used to derive master key but nothing stored\n• Passphrase NOT enough to recover wallets',
              onTap: () => _selectPassphraseMode(context, ref),
            ),

            const SizedBox(height: 20),

            // Important notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Always back up your wallet private keys!\nThey are your only way to recover funds in case of lost phone.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 32, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectBiometricMode(BuildContext context, WidgetRef ref) async {
    // Set up biometric mode (will show native biometric prompt)
    final success = await ref.read(localStorageServiceProvider).setupBiometricOnlyMode();

    if (success) {
      // Navigate to home
      if (context.mounted) {
        ref.read(localStorageServiceProvider).setLoginStatus(true);
        await Navigator.pushReplacementNamed(context, AuthRoutes.home);
      }
    } else {
      // Show error
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Setup Failed'),
              content: const Text('Failed to set up biometric authentication. Please try again or use passphrase mode.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _selectPassphraseMode(BuildContext context, WidgetRef ref) async {
    // Navigate to passphrase setup
    Navigator.pushReplacementNamed(
      context,
      AuthRoutes.setPassphrase,
      arguments: true, // isKeyboardFocused
    );
  }
}
