// Flutter imports:
import 'package:flutter/material.dart';

informationSnackBarMessage(BuildContext context, String? message) {
  if (message != null) {
    final double width = MediaQuery.of(context).size.width * 0.80;

    return ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          width: width,
          backgroundColor: Theme.of(context).cardColor,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          elevation: 6.0,
          duration: const Duration(milliseconds: 2000),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.blueGrey, width: 0.5),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
