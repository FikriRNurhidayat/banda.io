enum TransactionType {
  deposit('Deposit'),
  withdraw('Withdraw');

  final String label;
  const TransactionType(this.label);

  get isDeposit {
    return this == TransactionType.deposit;
  }

  get isWithdraw {
    return this == TransactionType.withdraw;
  }

  get isDisbursement {
    return false;
  }
}
