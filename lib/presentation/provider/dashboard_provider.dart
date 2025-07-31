// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardProvider extends StateNotifier<int> {
  DashboardProvider() : super(0);

  void changeIndexBottom({required int index}) {
    state = index;
    _debug();
  }

  void _debug() {
    log('Current tab: $state');
  }
}

final dashboardProvider = StateNotifierProvider<DashboardProvider, int>((ref) {
  print("dashboard provider initalised...");
  return DashboardProvider();
});
