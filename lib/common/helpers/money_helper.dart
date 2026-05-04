class MoneyHelper {
  static String sign(double amount) {
    return amount >= 0 ? "+" : "-";
  }

  static String string(double value) {
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String normalize(double amount) {
    final n = amount.abs();

    if (n >= 1e9) {
      return '${string(n / 1e9)}B';
    }
    if (n >= 1e6) {
      return '${string(n / 1e6)}M';
    }

    if (n >= 1e3) {
      return '${string(n / 1e3)}K';
    }

    return n.toStringAsFixed(0);
  }

  static format(double amount) {
    return "${sign(amount)}${normalize(amount)}";
  }
}
