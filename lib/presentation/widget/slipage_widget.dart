import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/presentation/provider/setting_provider.dart';
import 'package:mug/presentation/widget/information_snack_message.dart';

final slippageProvider = StateProvider<double>((ref) => 0.1); // Default to 0.1%

class SlippageWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the selected slippage value
    final setting = ref.watch(settingProvider);

    // List of slippage levels
    final List<double> slippageLevels = [0.1, 0.5, 1.0];

    return DropdownButton<double>(
      value: setting.slippage,
      items: slippageLevels.map((level) {
        return DropdownMenuItem<double>(
          value: level,
          child: Text('${level.toStringAsFixed(1)}%'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          ref.read(settingProvider.notifier).changeSlippage(slippage: value);
          informationSnackBarMessage(context, 'Slippage set to ${value.toStringAsFixed(1)}%');
        }
      },
      dropdownColor: Colors.grey.shade900,
      underline: Container(
        height: 2,
        color: Colors.blue,
      ),
      style: TextStyle(fontSize: 16, color: Colors.white),
    );
  }
}
