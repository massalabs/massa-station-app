import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateNotifier to manage the title state
class ScreenTitleNotifier extends StateNotifier<String> {
  ScreenTitleNotifier() : super("Screen");

  void updateTitle(String title) {
    state = title;
  }
}

// Provider for ScreenTitleNotifier
final screenTitleProvider = StateNotifierProvider<ScreenTitleNotifier, String>((ref) {
  return ScreenTitleNotifier();
});
