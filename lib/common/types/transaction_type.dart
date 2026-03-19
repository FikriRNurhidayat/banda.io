enum TransactionType {
  deposit('Deposit'),
  withdrawal('Withdrawal');

  final String label;
  const TransactionType(this.label);

  get isDeposit {
    return this == TransactionType.deposit;
  }

  get isWithdrawal {
    return this == TransactionType.withdrawal;
  }

  get isDisbursement {
    return false;
  }
}
