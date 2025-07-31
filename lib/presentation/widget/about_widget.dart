// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AboutWidget extends StatefulWidget {
  const AboutWidget({super.key});

  @override
  State<AboutWidget> createState() => _AboutState();
}

class _AboutState extends State<AboutWidget> {
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Massa Station'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/massa_station.png',
                height: 80,
                width: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Massa Station',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Mobile Version 0.1.0'),
              const SizedBox(height: 16),
              const Text('© 2025 Massa Labs'),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About'),
      onTap: () {
        _showAboutDialog();
      },
    );
  }
}
