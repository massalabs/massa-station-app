import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massa/massa.dart';
import 'package:mug/data/model/transaction_history.dart';
import 'package:mug/presentation/provider/wallet_provider.dart';
import 'package:mug/presentation/widget/information_snack_message.dart';
import 'package:mug/utils/string_helpers.dart';

Widget buildHeaderItem(String label, double width) {
  return Container(
    width: width,
    height: 56,
    //color: Colors.blue,
    decoration: BoxDecoration(
      color: Colors.grey[850],
      border: Border(
        bottom: BorderSide(color: Colors.brown[900]!, width: 0.1),
      ),
    ),
    child: Center(
      child: Text(
        label,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

Widget buildLeftSideItem(BuildContext context, String text, int index) {
  return Container(
    width: 100,
    height: 52,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: index % 2 == 0 ? Colors.grey[900] : Colors.grey[800],
      border: Border(
        bottom: BorderSide(color: Colors.brown[900]!, width: 0.1),
      ),
    ),
    child: TextButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text)).then((result) {
          if (context.mounted) {
            informationSnackBarMessage(context, "Operation copied!");
          }
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: index % 2 == 0 ? Colors.grey[900] : Colors.grey[800],
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.blueGrey, width: 1),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        shortenString(text, 10),
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    ),
  );
}

Widget buildRightSideItem(WidgetRef ref, BuildContext context, TransactionHistory history, int index) {
  return Row(
    children: [
      buildRightItem(ref.read(walletProvider.notifier).computeTimestampAge(int.parse(history.blockTime!)), 110, index),
      buildRightItem(history.status!, 70, index),
      buildRightItem(history.type!, 100, index),
      buildCopyRightItem(context, history.from!, 110, index),
      buildCopyRightItem(context, history.to!, 110, index),
      buildRightItem('${toMAS(BigInt.parse(history.value!))} MAS', 120, index),
      buildRightItem('${toMAS(BigInt.parse(history.transactionFee!))} MAS', 80, index),
    ],
  );
}

Widget buildRightItem(String text, double width, int index) {
  return Container(
    width: width,
    height: 52,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    decoration: BoxDecoration(
      color: index % 2 == 0 ? Colors.grey[900] : Colors.grey[800],
      border: Border(
        bottom: BorderSide(color: Colors.brown[900]!, width: 0.1),
      ),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
      ),
    ),
  );
}

Widget buildCopyRightItem(BuildContext context, String text, double width, int index) {
  return Container(
    width: width,
    height: 52,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    decoration: BoxDecoration(
      color: index % 2 == 0 ? Colors.grey[900] : Colors.grey[800],
      border: Border(
        bottom: BorderSide(color: Colors.brown[900]!, width: 0.1),
      ),
    ),
    child: TextButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text)).then((result) {
          if (context.mounted) {
            informationSnackBarMessage(context, "Address copied!");
          }
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: index % 2 == 0 ? Colors.grey[900] : Colors.grey[800],
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.blueGrey, width: 1),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        shortenString(text, 10),
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    ),
  );
}
