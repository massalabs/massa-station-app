// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/constants/constants.dart';

// Project imports:
import 'package:mug/presentation/provider/address_provider.dart';
import 'package:mug/presentation/state/address_state.dart';
import 'package:mug/presentation/widget/widget.dart';
import 'package:mug/utils/number_helpers.dart';
import 'package:mug/utils/string_helpers.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart' as ht;

class AddressView extends ConsumerStatefulWidget {
  final String address;
  const AddressView(this.address, {super.key});

  @override
  ConsumerState<AddressView> createState() => _AddressViewState();
}

class _AddressViewState extends ConsumerState<AddressView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      ref.read(addressProvider.notifier).getAddress(widget.address, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Address Details'),
      ),
      body: CommonPadding(
        child: RefreshIndicator(
          onRefresh: () {
            return ref.read(addressProvider.notifier).getAddress(widget.address, true);
          },
          child: Consumer(
            builder: (context, ref, child) {
              return switch (ref.watch(addressProvider)) {
                AddressInitial() => const Text('Address information is loading....'),
                AddressLoading() => const CircularProgressIndicator(),
                AddressSuccess(addressEntity: final addressEntity) => Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Card(
                              child: ListTile(
                                leading: SizedBox(width: 40, height: 40, child: AddressIcon(addressEntity.address)),
                                title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text(
                                    shortenString(addressEntity.address, 24),
                                    textAlign: TextAlign.left,
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: addressEntity.address)).then((result) {
                                          if (context.mounted) {
                                            informationSnackBarMessage(context, "Address copied!");
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.copy)),
                                ]),
                                subtitle:
                                    Text("Thread: ${addressEntity.thread.toString()}", textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Card(
                              child: ListTile(
                                leading: Text(
                                  "Total Assest",
                                  style: TextStyle(fontSize: Constants.fontSize),
                                ),
                                title: Text(
                                  formatNumber4(addressEntity.finalBalance + addressEntity.finalRolls * 100.00),
                                  textAlign: TextAlign.center,
                                ),
                                subtitle: const Text("MASSA", textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Card(
                              child: ListTile(
                                title: Text(formatNumber4(addressEntity.finalBalance), textAlign: TextAlign.center),
                                subtitle: const Text("Final Balance", textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              child: ListTile(
                                title: Text(formatNumber4(addressEntity.candidateBalance), textAlign: TextAlign.center),
                                subtitle: const Text("Candidate Balance", textAlign: TextAlign.center),
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Card(
                              child: ListTile(
                                title: Text(
                                  formatNumber(addressEntity.finalRolls.toDouble()),
                                  textAlign: TextAlign.center,
                                ),
                                subtitle: const Text("Final Rolls", textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              child: ListTile(
                                title: Text(
                                  formatNumber(addressEntity.candidateRolls.toDouble()),
                                  textAlign: TextAlign.center,
                                ),
                                subtitle: const Text("Candidate Rolls", textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Tabs for Assets and Transactions
                      Expanded(
                        child: DefaultTabController(
                          length: 3,
                          child: Column(
                            children: [
                              TabBar(
                                tabs: const [
                                  Tab(text: 'TRANSACTIONS'),
                                ],
                                labelColor: Colors.blue,
                                unselectedLabelColor: Colors.grey,
                                labelStyle: TextStyle(fontSize: Constants.fontSizeSmall),
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    if (addressEntity.transactionHistory != null)
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ht.HorizontalDataTable(
                                          leftHandSideColumnWidth: 100,
                                          rightHandSideColumnWidth: 700,
                                          isFixedHeader: true,
                                          leftHandSideColBackgroundColor: Theme.of(context).canvasColor,
                                          rightHandSideColBackgroundColor: Theme.of(context).canvasColor,
                                          headerWidgets: [
                                            buildHeaderItem('Hash', 100),
                                            buildHeaderItem('Age', 110),
                                            buildHeaderItem('Status', 70),
                                            buildHeaderItem('Type', 100),
                                            buildHeaderItem('From', 110),
                                            buildHeaderItem('To', 110),
                                            buildHeaderItem('Amount', 120),
                                            buildHeaderItem('Fee', 80),
                                          ],
                                          leftSideItemBuilder: (context, index) {
                                            final history = addressEntity.transactionHistory?.combinedHistory?[index];
                                            return buildLeftSideItem(context, shortenString(history!.hash!, 10), index);
                                          },
                                          rightSideItemBuilder: (context, index) {
                                            final history = addressEntity.transactionHistory?.combinedHistory?[index];
                                            return buildRightSideItem(ref, context, history!, index);
                                          },
                                          itemCount: addressEntity.transactionHistory!.combinedHistory!.length,
                                        ),
                                      ),
                                    if (addressEntity.transactionHistory == null)
                                      const Text("No transaction history found"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                AddressFailure(message: final message) => Text(message),
              };
            },
          ),
        ),
      ),
    );
  }
}
