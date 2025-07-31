import 'package:flutter/material.dart';

class CustomLabelWidget extends StatelessWidget {
  final String label;
  final Widget value;
  const CustomLabelWidget({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 10),
            child: value,
          ),
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 46, 53, 56),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ) // green shaped
                  ),
              child: Text(label),
            ),
          )
        ],
      ),
    );
  }
}
