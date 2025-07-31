import 'package:flutter/material.dart';
import 'package:mug/presentation/widget/generic.dart';

class HelpInfo extends StatelessWidget {
  final String message;
  const HelpInfo({required this.message, super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showGenericDialog(
          context: context,
          icon: Icons.info_outline,
          message: message,
        );
      },
      icon: const Icon(
        Icons.info_outline,
        color: Colors.blue,
      ),
    );
  }
}
