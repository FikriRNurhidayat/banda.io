enum ReadOnlyCategory {
  adjustment('Adjustment'),
  transfer('Transfer'),
  fund('Fund'),
  debt('Debt'),
  receivable('Receivable');

  final String label;
  const ReadOnlyCategory(this.label);
}
