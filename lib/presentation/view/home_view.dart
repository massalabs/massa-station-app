// Flutter imports:
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
  Widget _buildSwapView() {
    final selectedWallet = ref.watch(walletSelectionProvider);

    if (selectedWallet == null) {
      return Center(
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
    }

    // Skip DexView and go directly to swap with selected wallet
    // Allow even with insufficient balance - will be caught later
    return SwapView(selectedWallet.address);
  }

  final listOfWidgets = [
    const WalletsView(),
    null, // DexView will be handled by _buildSwapView()
    const ExplorerView(),
    const SettingView(),
  ];
  
  bool _showSettings = false;

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
    
    if (_showSettings) {
      return const SettingView();
    }
    
    // Only show wallet detail when on Wallets tab and a wallet is selected
    if (selectedWallet != null && state == 0) {
      return Column(
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
          Expanded(child: WalletView(selectedWallet)),
        ],
      );
    }
    
    // Handle Swap tab specially
    if (state == 1) {
      return _buildSwapView();
    }
    
    return listOfWidgets.elementAt(state)!;
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
        animationDuration: const Duration(milliseconds: 600),
        onDestinationSelected: (int index) {
          setState(() {
            _showSettings = false;
          });
          ref.read(dashboardProvider.notifier).changeIndexBottom(index: index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'WALLETS',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            label: 'SWAP',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'EXPLORE',
          ),
        ],
      ),
    );
  }
}
