// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

// Project imports:
import 'package:mug/presentation/provider/address_provider.dart';
import 'package:mug/presentation/provider/dashboard_provider.dart';
import 'package:mug/presentation/provider/transfer_provider.dart';
import 'package:mug/presentation/provider/wallet_list_provider.dart';
import 'package:mug/presentation/provider/wallet_provider.dart';
import 'package:mug/presentation/provider/wallet_selection_provider.dart';
import 'package:mug/presentation/state/transfer_state.dart';
import 'package:mug/presentation/view/explorer/explorer_view.dart';
import 'package:mug/presentation/view/dex/dex_view.dart';
import 'package:mug/presentation/view/dex/swap_view.dart';
import 'package:mug/presentation/view/settings/setting_view.dart';
import 'package:mug/presentation/view/wallet/wallets_view.dart';
import 'package:mug/presentation/view/wallet/wallet_view.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Home> {
  final listOfWidgets = [
    const WalletsView(),
    null, // SwapView will be built dynamically
    const ExplorerView(),
    const SettingView(),
  ];

  bool _showSettings = false;

  // Cache swap view widgets per address
  final Map<String, Widget> _swapViewCache = {};

  // Cache wallet detail widgets per address
  final Map<String, Widget> _walletDetailCache = {};

  Widget _buildAppBarTitle() {
    return MediaQuery.of(context).orientation == Orientation.portrait
        ? Image.asset(
            'assets/icons/massa_station_full.png',
            width: MediaQuery.of(context).size.width * 0.8,
            fit: BoxFit.contain,
          )
        : Image.asset(
            'assets/icons/massa_station_full.png',
            height: 40,
          );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        onPressed: () {
          setState(() {
            _showSettings = !_showSettings;
          });
        },
        icon: Icon(
          _showSettings ? Icons.close : Icons.settings_outlined,
        ),
      ),
    ];
  }

  Widget _buildBody() {
    final selectedWallet = ref.watch(walletSelectionProvider);
    final state = ref.watch(dashboardProvider);
    if (kDebugMode) {
      final buildBodyTime = DateTime.now();
      print('🟡 _buildBody called for tab $state at: ${buildBodyTime.millisecondsSinceEpoch}');
    }

    if (_showSettings) {
      return const SettingView();
    }

    // Use IndexedStack to keep all tabs alive for instant switching
    // Build swap view only once per wallet selection and cache it
    final swapViewWidget = selectedWallet != null
        ? _swapViewCache.putIfAbsent(
            selectedWallet.address,
            () => SwapView(selectedWallet.address, key: ValueKey(selectedWallet.address)),
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No wallet selected',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(dashboardProvider.notifier).changeIndexBottom(index: 0);
                    },
                    child: const Text('Select Wallet'),
                  ),
                ],
              ),
            ),
          );

    // Get or create the cached wallet view for the selected wallet
    Widget? walletDetailWidget;
    if (selectedWallet != null) {
      walletDetailWidget = _walletDetailCache.putIfAbsent(
        selectedWallet.address,
        () {
          print('📦 Creating new WalletView widget for ${selectedWallet.address}');
          return WalletView(selectedWallet, key: ValueKey(selectedWallet.address));
        },
      );
      print('📋 Using cached WalletView for ${selectedWallet.address}, cache size: ${_walletDetailCache.length}');
    }

    final indexedStack = IndexedStack(
      index: state,
      children: [
        listOfWidgets[0]!,  // WalletsView
        swapViewWidget,     // SwapView - cached per wallet
        listOfWidgets[2]!,  // ExplorerView
      ],
    );

    // Overlay wallet detail if needed (but keep widget in tree even when hidden)
    return Stack(
      children: [
        indexedStack,
        // Always include wallet detail in tree, but only show it when on wallet tab with selection
        if (walletDetailWidget != null)
          Offstage(
            offstage: !(selectedWallet != null && state == 0),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(walletSelectionProvider.notifier).clearSelection();
                      },
                      child: const Text('Change Wallet'),
                    ),
                  ),
                  Expanded(
                    child: walletDetailWidget,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    // Listen for transfer completion and show global snackbar
    ref.listen(transferProvider, (previous, next) {
      if (next is TransferSuccess) {
        // Refresh wallet balance and wallet list
        final senderAddress = next.transferEntity.sendingAddress;
        if (senderAddress != null) {
          ref.read(walletProvider.notifier).getWalletInformation(senderAddress, true);
        }
        ref.read(walletListProvider.notifier).loadWallets();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Transfer of ${next.transferEntity.amount} MAS successful!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (next is TransferFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Transfer failed: ${next.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        centerTitle: true,
        actions: _buildAppBarActions(),
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state,
        animationDuration: Duration.zero,
        onDestinationSelected: (int index) {
          final tapTime = DateTime.now();
          print('🔵 Tab $index tapped at: ${tapTime.millisecondsSinceEpoch}');
          setState(() {
            _showSettings = false;
          });
          ref.read(dashboardProvider.notifier).changeIndexBottom(index: index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'WALLETS',
            tooltip: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            label: 'SWAP',
            tooltip: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'EXPLORE',
            tooltip: '',
          ),
        ],
      ),
    );
  }
}
