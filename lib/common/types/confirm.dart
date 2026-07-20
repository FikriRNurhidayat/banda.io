enum Confirm {
  yes('Yes'),
  no('No');

  final String label;
  const Confirm(this.label);

  bool get value {
    return this == Confirm.yes;
  }
}
