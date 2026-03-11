enum ControllerType {
  entry('Entry'),
  budget('Budget'),
  fund('Fund'),
  transfer('Transfer'),
  loan('Loan'),
  loanPayment('Loan Payment'),
  bill('Bill'),
  purchase('Purchase'),
  unknown('Unknown');

  static parse(String name) {
    return ControllerType.values.firstWhere(
      (c) => c.name == name,
      orElse: () => ControllerType.unknown,
    );
  }

  static fromLabel(String label) {
    return ControllerType.values.firstWhere(
      (c) => c.label == label,
      orElse: () => ControllerType.unknown,
    );
  }

  get id {
    return label.toString().toLowerCase();
  }

  final String label;
  const ControllerType(this.label);
}
