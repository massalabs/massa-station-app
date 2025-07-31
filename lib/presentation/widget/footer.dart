// Flutter imports:
import 'package:flutter/material.dart';

Widget footer() {
  const double fontSize = 12;
  const Color color = Color(0xFFafb8ba);
  const TextStyle style = TextStyle(color: color, fontSize: fontSize);
  return const Padding(
    padding: EdgeInsets.only(bottom: 20),
    child: Text('Massa Labs', style: style),
  );
}
