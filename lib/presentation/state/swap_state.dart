// Project imports:
import 'package:dusa/tokens.dart';
import 'package:mug/domain/entity/swap_entity.dart';

// Enum to represent loading states
enum SwapStatus { loading, swap, success, error }

class DropdownItem {
  String name;
  String iconPath;
  TokenName token;
  DropdownItem({required this.name, required this.iconPath, required this.token});
}

class SwapState {
  final String? accountAddress;
  final String? selectedDropdown1;
  final String? selectedDropdown2;
  final double? balance1;
  final double? balance2;
  final double? value1;
  final double? value2;
  final double? exchangeRate;
  final SwapEntity? swapEntity;
  final Map<String, DropdownItem> allItems;
  final bool? showNotification;
  final String? notificationMessage;
  final SwapStatus status;

  SwapState({
    this.accountAddress,
    this.selectedDropdown1,
    this.selectedDropdown2,
    this.balance1,
    this.balance2,
    this.value1,
    this.value2,
    this.exchangeRate,
    this.swapEntity,
    required this.allItems,
    this.showNotification,
    this.notificationMessage,
    this.status = SwapStatus.loading,
  });

  // Create a copyWith method to update parts of the state
  SwapState copyWith({
    String? accountAddress,
    String? selectedDropdown1,
    String? selectedDropdown2,
    double? balance1,
    double? balance2,
    double? value1,
    double? value2,
    double? exchangeRate,
    SwapEntity? swapEntity,
    bool? showNotification,
    String? notificationMessage,
    SwapStatus? status,
  }) {
    return SwapState(
      accountAddress: accountAddress ?? this.accountAddress,
      selectedDropdown1: selectedDropdown1 ?? this.selectedDropdown1,
      selectedDropdown2: selectedDropdown2 ?? this.selectedDropdown2,
      balance1: balance1 ?? this.balance1,
      balance2: balance2 ?? this.balance2,
      value1: value1 ?? this.value1,
      value2: value2 ?? this.value2,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      swapEntity: swapEntity ?? this.swapEntity,
      allItems: allItems,
      showNotification: showNotification ?? this.showNotification,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      status: status ?? this.status,
    );
  }

  Map<String, DropdownItem> get dropdownItems {
    return allItems;
  }
}
