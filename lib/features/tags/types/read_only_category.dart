enum ReadOnlyCategory {
  adjustment('Adjustment'),
  transfer('Transfer'),
  pool('Pool'),
  commitment('Commitment');

  final String label;
  const ReadOnlyCategory(this.label);
}
