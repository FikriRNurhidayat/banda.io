enum ReadOnlyCategory {
  adjustment('Adjustment'),
  transfer('Transfer'),
  pool('Pool'),
  debt('Debt'),
  receivable('Receivable');

  final String label;
  const ReadOnlyCategory(this.label);
}
