class Metric {
  final String name;
  final String? label;
  final double value;
  final String? displayValue;

  const Metric({
    required this.name,
    this.label,
    required this.value,
    this.displayValue,
  });
}
