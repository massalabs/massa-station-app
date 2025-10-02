// Flutter imports:
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart' as ht;
import 'package:mug/constants/constants.dart';

// Project imports:
import 'package:mug/data/model/wallet_model.dart';
import 'package:mug/presentation/provider/dashboard_provider.dart';
import 'package:mug/presentation/provider/screen_title_provider.dart';
import 'package:mug/presentation/provider/setting_provider.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/presentation/provider/wallet_provider.dart';
import 'package:mug/presentation/provider/wallet_selection_provider.dart';
import 'package:mug/presentation/state/wallet_state.dart';
import 'package:mug/presentation/widget/widget.dart';
import 'package:mug/routes/routes_name.dart';
import 'package:mug/service/provider.dart';
import 'package:mug/utils/number_helpers.dart';
import 'package:mug/utils/string_helpers.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletViewArg {
  final String address;
  final String? name;
  final bool hasBalance;
  WalletViewArg(this.address, this.name, this.hasBalance);
}

class WalletView extends ConsumerStatefulWidget {
  final WalletViewArg arg;
  const WalletView(this.arg, {super.key});

  @override
  ConsumerState<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends ConsumerState<WalletView> with AutomaticKeepAliveClientMixin {
  static final Map<String, DateTime> _lastFetchMap = {};
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      final initTime = DateTime.now();
      print('🟢 WalletView initState for ${widget.arg.name ?? widget.arg.address} at: ${initTime.millisecondsSinceEpoch}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetch();
    });
  }

  void _fetch() {
    final now = DateTime.now();
    final key = widget.arg.address;
    _lastFetchMap[key] = now;
    if (kDebugMode) {
      print('💰 WalletView fetching data for $key');
    }
    ref.read(walletProvider.notifier).getWalletInformation(widget.arg.address, widget.arg.hasBalance);
    ref.read(walletNameProvider.notifier).loadWalletName(widget.arg.address);
  }

  @override
  void didUpdateWidget(WalletView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the wallet address changed, reload the wallet data
    if (oldWidget.arg.address != widget.arg.address) {
      if (kDebugMode) {
        print('🔄 WalletView address changed from ${oldWidget.arg.address} to ${widget.arg.address}');
      }
      _fetch();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetch();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final isDarkTheme = ref.watch(settingProvider).darkTheme;

    // Watch dashboard to detect when wallet tab is visible
    final currentTab = ref.watch(dashboardProvider);
    final walletSelection = ref.watch(walletSelectionProvider);
    final isVisible = currentTab == 0 && walletSelection != null;

    // Start/stop timer based on visibility
    if (isVisible) {
      if (_refreshTimer == null || !_refreshTimer!.isActive) {
        _startRefreshTimer();
      }
      // Fetch when becoming visible (rate-limited by timestamp)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final now = DateTime.now();
        final key = widget.arg.address;
        final lastFetch = _lastFetchMap[key];

        if (lastFetch == null || now.difference(lastFetch).inSeconds >= 10) {
          _fetch();
        }
      });
    } else {
      if (_refreshTimer != null && _refreshTimer!.isActive) {
        _stopRefreshTimer();
      }
    }

    // Use the name from the argument immediately to avoid flickering
    final walletName = widget.arg.name ?? shortenString(widget.arg.address, 4);
    if (kDebugMode) {
      final buildTime = DateTime.now();
      print('🟡 WalletView build for $walletName at: ${buildTime.millisecondsSinceEpoch}');
    }

    return Scaffold(
      body: CommonPadding(
        child: RefreshIndicator(
          onRefresh: () {
            return ref.read(walletProvider.notifier).getWalletInformation(widget.arg.address, widget.arg.hasBalance);
          },
          child: Consumer(
            builder: (context, ref, child) {
              return switch (ref.watch(walletProvider)) {
                WalletLoading() => const CircularProgressIndicator(),
                WalletSuccess(addressEntity: final addressEntity) => SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: AddressIcon(addressEntity.address),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            walletName,
                            style: TextStyle(fontSize: Constants.fontSizeExtraLarge),
                          ),
                        ]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Card(
                                child: ListTile(
                                  title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(
                                      shortenString(addressEntity.address, Constants.shortedAddressLength),
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: Constants.fontSize),
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: addressEntity.address)).then((result) {
                                            if (context.mounted) {
                                              informationSnackBarMessage(context, "Wallet address copied!");
                                            }
                                          });
                                        },
                                        icon: const Icon(Icons.copy)),
                                  ]),
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
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Balance: ${addressEntity.finalBalance < 0 ? '-' : '${formatNumber4(addressEntity.finalBalance)} MAS'}",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: Constants.fontSize),
                                      ),
                                      if (addressEntity.finalRolls >= 0 && addressEntity.finalRolls > 0)
                                        Text(
                                          "Rolls: ${addressEntity.finalRolls}",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: Constants.fontSize),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: Constants.verticalSpacing),
                        // Tabs for Assets and Transactions
                        DefaultTabController(
                          length: 3,
                          animationDuration: Duration.zero,
                          child: Column(
                            children: [
                              TabBar(
                                tabs: const [
                                  Tab(text: 'TOKENS'),
                                  Tab(text: 'TRANSACTIONS'),
                                  Tab(text: 'SETTING'),
                                ],
                                labelColor: Colors.blue,
                                unselectedLabelColor: Colors.grey,
                                labelStyle: TextStyle(fontSize: Constants.fontSizeExtraSmall),
                              ),
                              SizedBox(
                                height: 500, // or MediaQuery.of(context).size.height * 0.6, adjust as needed
                                child: TabBarView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    // Assets Tab
                                    addressEntity.tokenBalances == null
                                        ? const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Text('-', style: TextStyle(fontSize: 24)),
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(16.0),
                                            itemCount: addressEntity.tokenBalances?.length,
                                            itemBuilder: (context, index) {
                                              return Column(
                                                children: [
                                                  ListTile(
                                                    leading: SvgPicture.asset(addressEntity.tokenBalances![index].iconPath,
                                                        semanticsLabel: addressEntity.tokenBalances?[index].name.name,
                                                        height: 40.0,
                                                        width: 40.0),
                                                    title: Text(
                                                      '${addressEntity.tokenBalances?[index].balance}  ${addressEntity.tokenBalances?[index].name.name}',
                                                      style: TextStyle(fontSize: Constants.fontSize),
                                                    ),
                                                  ),
                                                  Divider(thickness: 0.5, color: Colors.brown[500]),
                                                ],
                                              );
                                            },
                                          ),

                                    addressEntity.transactionHistory != null
                                        ? Padding(
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
                                            return buildLeftSideItem(context, history!.hash!, index);
                                          },
                                          rightSideItemBuilder: (context, index) {
                                            final history = addressEntity.transactionHistory?.combinedHistory?[index];
                                            return buildRightSideItem(ref, context, history!, index);
                                          },
                                          itemCount: addressEntity.transactionHistory!.combinedHistory!.length,
                                            ),
                                          )
                                        : const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Text('-', style: TextStyle(fontSize: 24)),
                                            ),
                                          ),

                                    Column(
                                      children: [
                                        SizedBox(height: Constants.verticalSpacing),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Wallet Name: $walletName",
                                                style: TextStyle(fontSize: Constants.fontSize),
                                              ),
                                              OutlinedButton.icon(
                                                  onPressed: () async {
                                                    await Navigator.pushNamed(
                                                      context,
                                                      WalletRoutes.walleName,
                                                      arguments: addressEntity.address,
                                                    );
                                                  },
                                                  label: const Text("Edit"),
                                                  icon: const Icon(Icons.edit)),
                                            ],
                                          ),
                                        ),
                                        Divider(thickness: 0.5, color: Colors.brown[500]),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Private Key: ***",
                                                style: TextStyle(fontSize: Constants.fontSize),
                                              ),
                                              OutlinedButton.icon(
                                                  onPressed: () async {
                                                    // Re-authenticate before showing private key
                                                    final passphrase = await _showPassphraseDialog(context);
                                                    if (passphrase == null) return; // User cancelled

                                                    // Show loading dialog during PBKDF2
                                                    if (context.mounted) {
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible: false,
                                                        builder: (BuildContext context) {
                                                          return WillPopScope(
                                                            onWillPop: () async => false,
                                                            child: Dialog(
                                                              backgroundColor: Colors.transparent,
                                                              elevation: 0,
                                                              child: Container(
                                                                padding: const EdgeInsets.all(20),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.grey[900],
                                                                  borderRadius: BorderRadius.circular(10),
                                                                ),
                                                                child: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: const [
                                                                    CircularProgressIndicator(),
                                                                    SizedBox(height: 20),
                                                                    Text(
                                                                      'Verifying passphrase...',
                                                                      style: TextStyle(color: Colors.white),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    }

                                                    // Verify passphrase
                                                    final isValid = await ref.read(localStorageServiceProvider).verifyAndCacheMasterKey(passphrase);

                                                    // Close loading dialog
                                                    if (context.mounted) {
                                                      Navigator.of(context).pop();
                                                    }

                                                    if (!isValid) {
                                                      if (context.mounted) {
                                                        informationSnackBarMessage(context, "Wrong passphrase!");
                                                      }
                                                      return;
                                                    }

                                                    final wallet = await ref
                                                        .read(walletProvider.notifier)
                                                        .getWalletKey(addressEntity.address);

                                                    if (context.mounted) {
                                                      await privateKeyBottomSheet(context, wallet!, isDarkTheme);
                                                    }
                                                  },
                                                  label: const Text("Show"),
                                                  icon: const Icon(Icons.lock_open)),
                                            ],
                                          ),
                                        ),
                                        Divider(thickness: 0.5, color: Colors.brown[500]),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Remove Wallet",
                                                style: TextStyle(fontSize: Constants.fontSize, color: Colors.red),
                                              ),
                                              OutlinedButton.icon(
                                                  onPressed: () async {
                                                    await _showRemoveWalletDialog(context, addressEntity.address);
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    side: const BorderSide(color: Colors.red),
                                                  ),
                                                  label: const Text("Remove"),
                                                  icon: const Icon(Icons.delete_outline)),
                                            ],
                                          ),
                                        ),
                                        Divider(thickness: 0.5, color: Colors.brown[500]),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          color: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0, bottom: 16),
                                child: FilledButton.tonalIcon(
                                  onPressed: () async {
                                    if (addressEntity.finalBalance < 2 * ref.read(settingProvider).feeAmount) {
                                      informationSnackBarMessage(
                                          context, "Wallet balance is less than the required fee amount");
                                      return;
                                    }
                                    ref.read(screenTitleProvider.notifier).updateTitle("Transfer Fund");
                                    await Navigator.pushNamed(
                                      context,
                                      WalletRoutes.transfer,
                                      arguments: addressEntity,
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_outward),
                                  label: const Text('Send'),
                                  iconAlignment: IconAlignment.start,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 32.0, bottom: 16),
                                child: FilledButton.tonalIcon(
                                  onPressed: () {
                                    receiveBottomSheet(context, isDarkTheme, widget.arg.address);
                                  },
                                  icon: Transform.rotate(
                                    angle: 3.14,
                                    child: const Icon(Icons.arrow_outward),
                                  ),
                                  label: const Text('Receive'),
                                  iconAlignment: IconAlignment.start,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                WalletFailure(message: final message) => Text(message),
              };
            },
          ),
        ),
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final walletState = ref.watch(walletProvider);
          if (walletState is! WalletSuccess) {
            return const SizedBox.shrink();
          }
          final addressEntity = walletState.addressEntity;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              top: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      if (addressEntity.finalBalance < 2 * ref.read(settingProvider).feeAmount) {
                        informationSnackBarMessage(context, "Wallet balance is less than the required fee amount");
                        return;
                      }
                      ref.read(screenTitleProvider.notifier).updateTitle("Transfer Fund");
                      await Navigator.pushNamed(
                        context,
                        WalletRoutes.transfer,
                        arguments: addressEntity,
                      );
                    },
                    icon: const Icon(Icons.arrow_outward),
                    label: const Text('Send'),
                    iconAlignment: IconAlignment.start,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      receiveBottomSheet(context, isDarkTheme, widget.arg.address);
                    },
                    icon: Transform.rotate(
                      angle: 3.14,
                      child: const Icon(Icons.arrow_outward),
                    ),
                    label: const Text('Receive'),
                    iconAlignment: IconAlignment.start,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String?> receiveBottomSheet(BuildContext context, bool isDarkTheme, String address) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: 340,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: 20, right: 20, left: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Align items to the top
                children: <Widget>[
                  const Text(
                    'Wallet address',
                    style: TextStyle(fontSize: 20),
                  ),
                  QrImageView(
                    data: address,
                    version: QrVersions.auto,
                    eyeStyle: QrEyeStyle(
                        color: (isDarkTheme == true) ? Colors.white : Colors.black, eyeShape: QrEyeShape.circle),
                    dataModuleStyle: QrDataModuleStyle(
                      color: (isDarkTheme == true) ? Colors.white : Colors.black,
                    ),
                    size: 180.0,
                  ),
                  SizedBox(height: Constants.verticalSpacing),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      shortenString(address, Constants.shortedAddressLength),
                      textAlign: TextAlign.left,
                    ),
                    IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: address)).then((result) {
                            if (context.mounted) {
                              informationSnackBarMessage(context, "Wallet address copied!");
                            }
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.copy)),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showPassphraseDialog(BuildContext context) async {
    final passphraseController = TextEditingController();
    bool isHidden = true;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Passphrase'),
              content: TextField(
                controller: passphraseController,
                obscureText: isHidden,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Passphrase',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        isHidden = !isHidden;
                      });
                    },
                  ),
                ),
                onSubmitted: (value) {
                  Navigator.of(context).pop(value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(passphraseController.text);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRemoveWalletDialog(BuildContext context, String address) async {
    final shortAddress = shortenString(address, Constants.shortedAddressLength);
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Wallet'),
          content: Text(
            'Are you sure you want to remove $shortAddress wallet address?\n\nMake sure you have backed up your private key. This action cannot be undone!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _removeWallet(address);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeWallet(String address) async {
    if (kDebugMode) {
      print('Starting wallet removal for: $address');
    }

    // Get all wallets
    final walletString = await ref.read(localStorageServiceProvider).getStoredWallets();
    if (walletString.isEmpty) {
      if (kDebugMode) {
        print('No wallets found');
      }
      return;
    }

    final wallets = WalletModel.decode(walletString);
    if (kDebugMode) {
      print('Current wallet count: ${wallets.length}');
    }

    // Check if this is the only wallet
    if (wallets.length == 1) {
      if (kDebugMode) {
        print('Cannot remove last wallet');
      }
      if (mounted) {
        informationSnackBarMessage(context, "Cannot remove the last wallet!");
      }
      return;
    }

    // Remove the wallet
    wallets.removeWhere((wallet) => wallet.address == address);
    if (kDebugMode) {
      print('Wallets after removal: ${wallets.length}');
    }
    await ref.read(localStorageServiceProvider).storeWallets(WalletModel.encode(wallets));

    // Check if this was the default wallet
    final defaultWallet = await ref.read(localStorageServiceProvider).getDefaultWallet();
    if (kDebugMode) {
      print('Default wallet: $defaultWallet');
    }
    if (defaultWallet == address) {
      if (kDebugMode) {
        print('Removed wallet was default, setting new default: ${wallets.first.address}');
      }
      await ref.read(localStorageServiceProvider).setDefaultWallet(wallets.first.address);
      ref.invalidate(accountProvider);
      ref.invalidate(smartContractServiceProvider);
    }

    if (mounted) {
      if (kDebugMode) {
        print('Clearing wallet selection to go back to list');
      }
      // Clear the wallet selection to return to wallet list
      ref.read(walletSelectionProvider.notifier).clearSelection();

      // Reload wallet list
      if (kDebugMode) {
        print('Reloading wallet list');
      }
      await ref.read(walletListProvider.notifier).loadWallets();

      if (kDebugMode) {
        print('Showing success message');
      }
      informationSnackBarMessage(context, "Wallet removed successfully!");
    }
  }

  Future<bool?> privateKeyBottomSheet(BuildContext context, String privateKey, bool isDarkTheme) async {
    return await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return PrivateKeyBottomSheet(privateKey, isDarkTheme);
      },
    );
  }

  Future<bool?> defaultAccountBottomSheet(BuildContext context, String address) async {
    return await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return DefaultAccountBottomSheet(address);
      },
    );
  }
}
