import 'package:bandha/features/accounts/entities/account.dart';
import 'package:flutter/material.dart';

class AccountText extends StatelessWidget {
  final Account account;

  const AccountText(this.account, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      account.displayName(),
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall,
    );
  }
}
