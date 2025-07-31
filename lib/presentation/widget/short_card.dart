import 'package:flutter/material.dart';

class ShortCard extends StatelessWidget {
  final String labelText;
  final String valueText;
  final Icon? leadingIcon;
  const ShortCard({required this.labelText, required this.valueText, this.leadingIcon, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
      leading: leadingIcon,
      title: Text(labelText),
      trailing: Text(valueText, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.left),
    ));
  }
}
