enum ReadOnlyLabel {
  fee('Fee'),
  deposit('Deposit'),
  credit('Credit'),
  debit('Debit'),
  disbursement('Disbursement'),
  obligation('Obligation'),
  payment('Payment'),
  withdraw('Withdraw'),
  retracted('Retracted'),
  released('Released');

  final String label;
  const ReadOnlyLabel(this.label);
}
