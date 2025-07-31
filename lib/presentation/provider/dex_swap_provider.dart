import 'package:dusa/dusa.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mug/constants/asset_names.dart';

// Enum to represent loading states
enum DexSwapStatus { loading, success, error, submitting }

class DropdownItem {
  String name;
  String iconPath;
  TokenName token;
  DropdownItem({required this.name, required this.iconPath, required this.token});
}

// State class to hold the data for both dropdowns
class DexSwapState {
  final String? selectedDropdown1;
  final String? selectedDropdown2;
  final double? balance1;
  final double? balance2;
  final double? value1;
  final double? value2;
  final double? exchangeRate;
  final Map<String, DropdownItem> allItems;
  final DexSwapStatus status;

  DexSwapState({
    this.selectedDropdown1,
    this.selectedDropdown2,
    this.balance1,
    this.balance2,
    this.value1,
    this.value2,
    this.exchangeRate,
    required this.allItems,
    this.status = DexSwapStatus.loading,
  });

  // Create a copyWith method to update parts of the state
  DexSwapState copyWith({
    String? selectedDropdown1,
    String? selectedDropdown2,
    double? balance1,
    double? balance2,
    double? value1,
    double? value2,
    double? exchangeRate,
    DexSwapStatus? status,
  }) {
    return DexSwapState(
      selectedDropdown1: selectedDropdown1 ?? this.selectedDropdown1,
      selectedDropdown2: selectedDropdown2 ?? this.selectedDropdown2,
      balance1: balance1 ?? this.balance1,
      balance2: balance2 ?? this.balance2,
      value1: value1 ?? this.value1,
      value2: value2 ?? this.value2,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      allItems: allItems,
      status: status ?? this.status,
    );
  }

  Map<String, DropdownItem> get dropdownItems {
    return allItems;
  }
}

// The StateNotifier that manages the dropdown state
class DropdownNotifier extends StateNotifier<DexSwapState> {
  DropdownNotifier()
      : super(DexSwapState(
          selectedDropdown1: "MAS",
          selectedDropdown2: "USDC",
          balance1: 0.0,
          balance2: 0.0,
          value1: 0.0,
          value2: 0.0,
          exchangeRate: 0.5,
          allItems: {
            'WETH': DropdownItem(name: "WETH", iconPath: AssetName.eth, token: TokenName.WETH),
            'MAS': DropdownItem(name: "MAS", iconPath: AssetName.mas, token: TokenName.WMAS),
            'WMAS': DropdownItem(name: "WMAS", iconPath: AssetName.wmas, token: TokenName.WMAS),
            'USDC': DropdownItem(name: "USDC", iconPath: AssetName.usdc, token: TokenName.USDC),
          },
        ));

  // Method to update the selected item in Dropdown 1
  void selectDropdown1(String? newValue) {
    if (newValue != 'MAS') {
      state = state.copyWith(selectedDropdown1: newValue, selectedDropdown2: "MAS");
    } else if (newValue == 'MAS' && state.selectedDropdown2 == 'MAS') {
      state = state.copyWith(selectedDropdown1: newValue, selectedDropdown2: "WMAS");
    }
  }

  // Method to update the selected item in Dropdown 2
  void selectDropdown2(String? newValue) {
    if (newValue != 'MAS') {
      state = state.copyWith(selectedDropdown1: "MAS", selectedDropdown2: newValue);
    } else if (newValue == 'MAS' && state.selectedDropdown1 == 'MAS') {
      state = state.copyWith(selectedDropdown1: "WMAS", selectedDropdown2: newValue);
    }
  }

  void updateBalances(double? balance1, double? balance2) {
    state = state.copyWith(balance1: balance1 ?? state.balance1, balance2: balance2 ?? state.balance2);
  }

  void updateValues(double? value1, double? value2) {
    state = state.copyWith(value1: value1 ?? state.value1, value2: value2 ?? state.value2);
  }

  void updateExchangeRate(double value) {
    state = state.copyWith(exchangeRate: value);
  }

  void flipTokens() {
    state = state.copyWith(
      selectedDropdown1: state.selectedDropdown2,
      selectedDropdown2: state.selectedDropdown1,
      balance1: state.balance2,
      balance2: state.balance1,
      value1: state.value2,
      value2: state.value1,
    );
  }
}

// The provider that will manage the dropdown state
final dropdownProvider = StateNotifierProvider<DropdownNotifier, DexSwapState>((ref) {
  print("dropdwon provider initalised...");
  return DropdownNotifier();
});
