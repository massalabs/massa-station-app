// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

class GenericDialog extends StatelessWidget {
  final IconData icon;
  final String message;

  const GenericDialog({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    const double dialogBordeRadious = 10.0;

    return BackdropFilter(
      filter: ImageFilter.blur(),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogBordeRadious),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //_buildIcon(context),
              _body(context),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }
  // }

  Widget _body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        message,
        //style: dialogBodyTextStyle,
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    const double buttonTextFontSize = 15.0;
    const String okButtonText = 'OK';

    return Container(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.zero, // Set this
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15), // and this
        ),
        child: _buttonText(okButtonText, buttonTextFontSize),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buttonText(String text, double fontSize) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        //color: Style.buttonTextStyle().color,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    );
  }
}

showGenericDialog({
  required BuildContext context,
  required IconData icon,
  required String message,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return GenericDialog(
        icon: icon,
        message: message,
      );
    },
  );
}
