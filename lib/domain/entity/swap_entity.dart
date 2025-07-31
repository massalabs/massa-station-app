import 'package:dusa/dusa.dart';

class SwapEntity {
  final String selectedToken1;
  final String selectedToken2;
  final TokenName token1;
  final TokenName token2;
  final double amountIn;
  final double amountOut;
  final double? slipagePercentage;

  final double? token1Balance;
  final double? token2Balance;
  final double? exchangeRate;

  final List<dynamic>? binSteps;
  final List<dynamic>? tokenPath;

  const SwapEntity({
    required this.selectedToken1,
    required this.selectedToken2,
    required this.token1,
    required this.token2,
    required this.amountIn,
    required this.amountOut,
    this.slipagePercentage,
    this.token1Balance,
    this.token2Balance,
    this.exchangeRate,
    this.binSteps,
    this.tokenPath,
  });

  SwapEntity copyWith({
    String? selectedToken1,
    String? selectedToken2,
    TokenName? token1,
    TokenName? token2,
    double? amountIn,
    double? amountOut,
    double? slipagePercentage,
    double? token1Balance,
    double? token2Balance,
    double? exchangeRate,
    List<dynamic>? binSteps,
    List<dynamic>? tokenPath,
  }) {
    return SwapEntity(
      selectedToken1: selectedToken1 ?? this.selectedToken1,
      selectedToken2: selectedToken2 ?? this.selectedToken2,
      token1: token1 ?? this.token1,
      token2: token2 ?? this.token2,
      amountIn: amountIn ?? this.amountIn,
      amountOut: amountOut ?? this.amountOut,
      slipagePercentage: slipagePercentage ?? this.slipagePercentage,
      token1Balance: token1Balance ?? this.token1Balance,
      token2Balance: token2Balance ?? this.token2Balance,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      binSteps: binSteps ?? this.binSteps,
      tokenPath: tokenPath ?? this.tokenPath,
    );
  }
}
