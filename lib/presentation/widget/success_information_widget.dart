import 'package:flutter/material.dart';

class SuccessInformationWidget extends StatelessWidget {
  final String message;
  const SuccessInformationWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 243, 243, 243), // Light information background color
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check,
                color: Color.fromARGB(255, 2, 132, 41), // Information icon color
                size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Color.fromARGB(255, 2, 132, 41), // Text color to match the theme
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
