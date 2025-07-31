import 'package:flutter/material.dart';

class InformationCardWidget extends StatelessWidget {
  final String message;
  const InformationCardWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade800, // Light information background color
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline,
                color: Colors.yellowAccent, // Information icon color
                size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white, // Text color to match the theme
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
