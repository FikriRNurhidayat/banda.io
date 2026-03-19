enum ReadOnlyLabel {
  fee('Fee'),
  deposit('Deposit'),
  credit('Credit'),
  debit('Debit'),
  disbursement('Disbursement'),
  commitment('Commitment'),
  payment('Payment'),
  withdraw('Withdraw'),
  retracted('Retracted'),
  released('Released');

  final String label;
  const ReadOnlyLabel(this.label);
}
