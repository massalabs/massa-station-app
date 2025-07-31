// Flutter imports:
import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onClicked;
  final bool isDarkTheme;

  const ButtonWidget({
    super.key,
    required this.isDarkTheme,
    required this.text,
    required this.onClicked,
  });

  @override
  Widget build(BuildContext context) {
    const double topSpacing = 10.0;

    return Padding(
      padding: const EdgeInsets.only(top: topSpacing),
      child: SizedBox(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shadowColor: isDarkTheme ? ThemeData.dark().primaryColor : ThemeData.light().primaryColor,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5.0,
          ),
          onPressed: onClicked,
          child: FittedBox(
            child: Text(
              text,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}
