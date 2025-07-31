import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mug/constants/constants.dart';
import 'package:mug/presentation/widget/information_snack_message.dart';
import 'package:mug/utils/string_helpers.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PrivateKeyBottomSheet extends StatelessWidget {
  final String privateKey;
  final bool isDarkTheme;
  const PrivateKeyBottomSheet(this.privateKey, this.isDarkTheme, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("PRIVATE KEY", style: TextStyle(fontSize: Constants.fontSizeLarge, color: Colors.blue)),
          SizedBox(height: Constants.verticalSpacing),
          QrImageView(
            data: privateKey,
            version: QrVersions.auto,
            eyeStyle:
                QrEyeStyle(color: (isDarkTheme == true) ? Colors.white : Colors.black, eyeShape: QrEyeShape.circle),
            dataModuleStyle: QrDataModuleStyle(
              color: (isDarkTheme == true) ? Colors.white : Colors.black,
            ),
            size: 180.0,
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              shortenString(privateKey, Constants.shortedAddressLength),
              textAlign: TextAlign.left,
            ),
            IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: privateKey)).then((result) {
                    if (context.mounted) {
                      informationSnackBarMessage(context, 'Private key copied');
                    }
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy)),
          ]),
          //Text("Private Key: $privateKey", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          const Text(
            "Your key is your digital asset. Keep it secure and do not share it.",
            style: TextStyle(color: Colors.amber),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              label: const Text("Close"),
              icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
