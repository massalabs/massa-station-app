import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DefaultAccountBottomSheet extends StatelessWidget {
  final String address;
  const DefaultAccountBottomSheet(this.address, {super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        //final isDarkTheme = ref.watch(settingProvider).darkTheme;

        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("CONFIRMATION", style: TextStyle(fontSize: 20, color: Colors.blue)),
              const SizedBox(height: 20),
              Text("Wallet Address: $address", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              const Text(
                  "Default wallet will be used to sign all smart contract transactions and pay the gas fee. Are you sure you want to make this wallet as default?"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      label: const Text("Yes"),
                      icon: const Icon(Icons.check)),
                  OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      label: const Text("No"),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
