import 'package:flutter/material.dart';

class LabelCard extends StatelessWidget {
  final String labelText;
  final String valueText;
  final Icon? leadingIcon;
  const LabelCard({required this.labelText, required this.valueText, this.leadingIcon, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
      leading: leadingIcon,
      title: Text(labelText),
      subtitle: Text(valueText),
    ));
  }
}
