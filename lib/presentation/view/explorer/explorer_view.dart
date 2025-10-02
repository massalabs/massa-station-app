// Flutter imports:
import 'dart:async';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/constants/constants.dart';
import 'package:mug/presentation/provider/dashboard_provider.dart';
import 'package:mug/presentation/provider/search_provider.dart';

// Project imports:
import 'package:mug/presentation/provider/staker_provider.dart';
import 'package:mug/presentation/state/staker_state.dart';
import 'package:mug/presentation/view/explorer/domain_view.dart';
import 'package:mug/routes/routes.dart';
import 'package:mug/utils/number_helpers.dart';
import 'package:mug/utils/string_helpers.dart';
import 'package:mug/presentation/widget/widget.dart';

class ExplorerView extends ConsumerStatefulWidget {
  const ExplorerView({super.key});
  @override
  ConsumerState<ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends ConsumerState<ExplorerView> with AutomaticKeepAliveClientMixin {
  static DateTime? _lastFetch;
  Timer? _refreshTimer;
  bool _hasInitialFetch = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch on init if we're on the explorer tab
      final currentTab = ref.read(dashboardProvider);
      if (currentTab == 2) {
        _fetch();
        _hasInitialFetch = true;
      }
    });
  }

  void _fetch() {
    final now = DateTime.now();
    _lastFetch = now;
    print('🔍 ExplorerView fetching stakers data');
    ref.read(stakerProvider.notifier).getStakers(0);
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


  final TextEditingController _searchText = TextEditingController();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch dashboard to detect when explorer tab is visible
    final currentTab = ref.watch(dashboardProvider);
    final isVisible = currentTab == 2;

    // Start/stop timer based on visibility
    if (isVisible) {
      if (_refreshTimer == null || !_refreshTimer!.isActive) {
        _startRefreshTimer();
      }
      // Fetch when becoming visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // If no initial fetch yet, fetch immediately
        if (!_hasInitialFetch) {
          _fetch();
          _hasInitialFetch = true;
          return;
        }

        // Otherwise rate-limit by timestamp
        final now = DateTime.now();
        final lastFetch = _lastFetch;

        if (lastFetch == null || now.difference(lastFetch).inSeconds >= 10) {
          _fetch();
        }
      });
    } else {
      if (_refreshTimer != null && _refreshTimer!.isActive) {
        _stopRefreshTimer();
      }
    }

    return Scaffold(
      body: CommonPadding(
        child: RefreshIndicator(
          onRefresh: () {
            return ref.read(stakerProvider.notifier).getStakers(0); //fixme: pass current page
          },
          child: Consumer(
            builder: (context, ref, child) {
              final stakerState = ref.watch(stakerProvider);

              return Column(
                children: [
                  // Always show stats cards (with placeholder or real data)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Card(
                          child: ListTile(
                            title: Text(
                              stakerState is StakersSuccess
                                  ? formatNumber(stakerState.stakers.stakerNumbers.toDouble())
                                  : "...",
                              textAlign: TextAlign.center,
                            ),
                            subtitle: const Text("Stakers", textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: ListTile(
                            title: Text(
                              stakerState is StakersSuccess
                                  ? formatNumber(stakerState.stakers.totalRolls.toDouble())
                                  : "...",
                              textAlign: TextAlign.center,
                            ),
                            subtitle: const Text("Rolls", textAlign: TextAlign.center),
                          ),
                        ),
                      )
                    ],
                  ),
                  // Always show search bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Card(
                          child: TextField(
                            controller: _searchText,
                            onChanged: (value) {
                              if (stakerState is StakersSuccess) {
                                ref.read(stakerProvider.notifier).filterStakers(value);
                              }
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search address/block/operation/mns...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            style: TextStyle(fontSize: Constants.fontSizeExtraSmall),
                            textAlignVertical: TextAlignVertical.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content based on state
                  Expanded(
                    child: _buildContent(stakerState),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(StakerState state) {
    return switch (state) {
      StakerInitial() => const Center(child: Text('Loading...')),
      StakerLoading() => const Center(child: CircularProgressIndicator()),
      StakersSuccess(stakers: final stakers) => stakers.stakers.isEmpty
          ? ButtonWidget(
              isDarkTheme: true,
              text: "Search",
              onClicked: () async {
                final searchType = ref.read(searchProvider.notifier).getSearchType(_searchText.text);
                switch (searchType) {
                  case SearchType.address:
                    await Navigator.pushNamed(
                      context,
                      ExploreRoutes.address,
                      arguments: _searchText.text,
                    );
                  case SearchType.block:
                    await Navigator.pushNamed(
                      context,
                      ExploreRoutes.block,
                      arguments: _searchText.text,
                    );
                  case SearchType.operation:
                    await Navigator.pushNamed(
                      context,
                      ExploreRoutes.operation,
                      arguments: _searchText.text,
                    );
                  case SearchType.mns:
                    await Navigator.pushNamed(
                      context,
                      ExploreRoutes.domain,
                      arguments: DomainArguments(domainName: _searchText.text, isNewDomain: false),
                    );
                  case SearchType.unknown:
                    await Navigator.pushNamed(
                      context,
                      ExploreRoutes.notFound,
                      arguments: _searchText.text,
                    );
                }
              },
            )
          : ListView.builder(
              itemCount: stakers.stakers.length,
              itemBuilder: (BuildContext context, int index) {
                final staker = stakers.stakers[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      ExploreRoutes.address,
                      arguments: staker.address,
                    );
                  },
                  child: Card(
                    child: ListTile(
                      leading: Text(staker.rank.toString(), style: TextStyle(fontSize: Constants.fontSize)),
                      title: Text(
                        shortenString(staker.address, Constants.shortedAddressLength),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Ownership: ${formatNumber4(staker.ownershipPercentage)} %"),
                          Text("Est. Daily Reward: ${formatNumber2(staker.estimatedDailyReward)} MAS"),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(formatNumber(staker.rolls.toDouble()),
                              style: TextStyle(fontSize: Constants.fontSize)),
                          const Text("rolls"),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      StakerFailure(message: final message) => Center(child: Text(message)),
    };
  }
}
