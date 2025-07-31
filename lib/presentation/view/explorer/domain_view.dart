// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/presentation/provider/domain_provider.dart';
import 'package:mug/presentation/state/domain_state.dart';
import 'package:mug/presentation/widget/widget.dart';

class DomainArguments {
  final String domainName;
  final bool isNewDomain;

  DomainArguments({
    required this.domainName,
    required this.isNewDomain,
  });
}

class DomainView extends ConsumerStatefulWidget {
  final DomainArguments arg;
  const DomainView(this.arg, {super.key});

  @override
  ConsumerState<DomainView> createState() => _DomainViewState();
}

class _DomainViewState extends ConsumerState<DomainView> {
  late String mns;
  late double domainPrice;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      ref.read(domainProvider.notifier).getDomain(widget.arg.domainName);
      final result = _getDomainPrice();
      mns = result.$2;
      domainPrice = result.$1;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Domain Details'),
      ),
      body: CommonPadding(
        child: RefreshIndicator(
          onRefresh: () {
            return ref.read(domainProvider.notifier).getDomain(widget.arg.domainName);
          },
          child: Consumer(
            builder: (context, ref, child) {
              return switch (ref.watch(domainProvider)) {
                DomainInitial() => const Text('Domain information is loading....'),
                DomainLoading() => const CircularProgressIndicator(),
                DomainSuccess(domainEntity: final domainEntry) => Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (widget.arg.isNewDomain)
                        const InformationCardWidget(message: "Domain purchased successfully!"),
                      LabelCard(
                        labelText: "Domain",
                        valueText: widget.arg.domainName,
                        leadingIcon: const Icon(Icons.language, size: 30),
                      ),
                      LabelCard(
                        labelText: "Owner Address",
                        valueText: domainEntry.ownerAddress,
                        leadingIcon: const Icon(Icons.person, size: 30),
                      ),
                      LabelCard(
                        labelText: "Target Address",
                        valueText: domainEntry.targetAddress,
                        leadingIcon: const Icon(Icons.gps_fixed, size: 30),
                      ),
                      ShortCard(
                        labelText: "Token ID",
                        valueText: domainEntry.tokenId,
                        leadingIcon: const Icon(Icons.local_offer, size: 30),
                      ),
                    ],
                  ),
                DomainFailure(message: final message) => MNSWidget(
                    domainName: mns,
                    domainPrice: domainPrice,
                  )
              };
            },
          ),
        ),
      ),
    );
  }

  (double, String) _getDomainPrice() {
    final spittedDomain = widget.arg.domainName.split(".");
    if (spittedDomain.length < 2) {
      return (0.0, "");
    }

    switch (spittedDomain[0].length) {
      case 2:
        return (10000.1, spittedDomain[0]);
      case 3:
        return (1000.1, spittedDomain[0]);
      case 4:
        return (100.1, spittedDomain[0]);
      case 5:
        return (10.1, spittedDomain[0]);
      default:
        return (1.1, spittedDomain[0]);
    }
  }
}
