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

  String formatAmount(double value, [int precision = 3]) {
    final s = value.toString();
    final parts = s.split('.');

    if (parts.length == 1) return s;

    final decimals = parts[1].substring(
      0,
      parts[1].length < precision ? parts[1].length : precision,
    );

    final result = "${parts[0]}.$decimals".replaceFirst(
      RegExp(r'\.?0+$'),
      '',
    );

    return result;
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
            fontFamily: theme.textTheme.bodyLarge!.fontFamily,
          ),
    );
  }
}
