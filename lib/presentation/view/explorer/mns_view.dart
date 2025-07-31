// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:

// Project imports:
import 'package:mug/presentation/widget/widget.dart';

class MNSArguments {
  final bool isSuccess;
  final String domainName;
  final String ownerAddress;
  final double domainPrice;
  final String operationID;

  MNSArguments(
      {required this.isSuccess,
      required this.domainName,
      required this.ownerAddress,
      required this.domainPrice,
      required this.operationID});
}

class MNSView extends StatelessWidget {
  final MNSArguments arg;
  const MNSView(this.arg, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('Domain Purchased'),
        ),
        body: CommonPadding(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (arg.isSuccess) const InformationCardWidget(message: "Domain purchased successfully!"),
              LabelCard(
                labelText: "Domain",
                valueText: "${arg.domainName}.massa",
                leadingIcon: const Icon(Icons.language, size: 30),
              ),
              LabelCard(
                labelText: "Owner Address",
                valueText: arg.ownerAddress,
                leadingIcon: const Icon(Icons.person, size: 30),
              ),
              LabelCard(
                labelText: "Target Address",
                valueText: arg.ownerAddress,
                leadingIcon: const Icon(Icons.gps_fixed, size: 30),
              ),
              LabelCard(
                labelText: "Transactrion ID",
                valueText: arg.operationID,
                leadingIcon: const Icon(Icons.local_offer, size: 30),
              ),
            ],
          ),
        ));
  }
}
