// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:mug/presentation/provider/operation_provider.dart';
import 'package:mug/presentation/state/operation_state.dart';
import 'package:mug/presentation/widget/widget.dart';

class OperationView extends ConsumerStatefulWidget {
  final String operationHash;
  const OperationView(this.operationHash, {super.key});

  @override
  ConsumerState<OperationView> createState() => _OperationViewState();
}

class _OperationViewState extends ConsumerState<OperationView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      ref.read(operationProvider.notifier).getOperation(widget.operationHash);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Operation Details'),
      ),
      body: CommonPadding(
        child: RefreshIndicator(
          onRefresh: () {
            return ref.read(operationProvider.notifier).getOperation(widget.operationHash);
          },
          child: Consumer(
            builder: (context, ref, child) {
              return switch (ref.watch(operationProvider)) {
                OperationInitial() => const Text('Operation information is loading....'),
                OperationLoading() => const CircularProgressIndicator(),
                OperationSuccess(operationEntity: final operationEntity) => Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      LabelCard(
                          labelText: "Operation ID",
                          valueText: operationEntity.id!,
                          leadingIcon: const Icon(Icons.layers, size: 24)),
                      LabelCard(
                          labelText: "Operation Creator",
                          valueText: operationEntity.operation.contentCreatorAddress,
                          leadingIcon: const Icon(Icons.developer_mode, size: 24)),
                      LabelCard(labelText: "Public Key", valueText: operationEntity.operation.contentCreatorPubKey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ShortCard(
                                labelText: "Status", valueText: operationEntity.isFinal! ? "Final" : "Pending"),
                          ),
                          Expanded(
                              child: ShortCard(
                                  labelText: "Execution",
                                  valueText: operationEntity.opExecutionStatus! ? "Final" : "Failed")),
                        ],
                      ),
                      ShortCard(
                          labelText: "Operation ",
                          valueText: operationEntity.thread!.toString(),
                          leadingIcon: const Icon(Icons.timer, size: 24)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                              child: ShortCard(labelText: "Fee", valueText: operationEntity.operation.content.fee)),
                          Expanded(
                              child: ShortCard(
                            labelText: "Expires",
                            valueText: operationEntity.operation.content.expirePeriod.toString(),
                          )),
                        ],
                      ),
                      if (operationEntity.operation.content.op.buyRoll != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Expanded(child: ShortCard(labelText: "Operation", valueText: "Buy Rolls")),
                            Expanded(
                                child: ShortCard(
                              labelText: "Rolls",
                              valueText: operationEntity.operation.content.op.buyRoll!.rollCount.toString(),
                            )),
                          ],
                        ),
                      if (operationEntity.operation.content.op.sellRoll != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Expanded(child: ShortCard(labelText: "Operation", valueText: "Sell Rolls")),
                            Expanded(
                                child: ShortCard(
                              labelText: "Rolls",
                              valueText: operationEntity.operation.content.op.sellRoll!.rollCount.toString(),
                            )),
                          ],
                        ),
                      if (operationEntity.operation.content.op.callSC != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Expanded(child: ShortCard(labelText: "Operation", valueText: "Call SC")),
                            Expanded(
                                child: ShortCard(
                              labelText: "Gass",
                              valueText: operationEntity.operation.content.op.callSC!.maxGas.toString(),
                            )),
                          ],
                        ),
                    ],
                  ),
                OperationFailure(message: final message) => message.contains("data")
                    ? NoSearchResult(
                        searchText: widget.operationHash,
                      )
                    : const Text("something went wrong")
              };
            },
          ),
        ),
      ),
    );
  }
}
