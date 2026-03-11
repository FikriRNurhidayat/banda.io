import 'package:flutter/material.dart';

class MoneyText extends StatelessWidget {
  final double amount;
  final String currency;
  final bool useSymbol;
  final TextStyle? style;

  const MoneyText(
    this.amount, {
    super.key,
    this.currency = 'IDR',
    this.useSymbol = true,
    this.style,
  });

  String getSign() {
    return amount >= 0 ? "+" : "-";
  }

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    return amount >= 0 ? theme.colorScheme.onSurface : theme.colorScheme.error;
  }

  String formatAmount(double value) {
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), ''); // trims .000 / .100 etc.
  }

  String getAmount() {
    final n = amount.abs();

    if (n >= 1e9) {
      return '${formatAmount(n / 1e9)}B';
    }
    if (n >= 1e6) {
      return '${formatAmount(n / 1e6)}M';
    }

    if (n >= 1e3) {
      return '${formatAmount(n / 1e3)}K';
    }

    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      "${useSymbol ? '${getSign()} ' : ''}${getAmount()}",
      textAlign: TextAlign.center,
      style:
          style ??
          theme.textTheme.bodyLarge!.apply(
            color: getColor(context),
            fontFamily: theme.textTheme.bodyLarge!.fontFamily,
          ),
    );
  }
}
