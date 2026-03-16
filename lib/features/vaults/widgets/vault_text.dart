import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:flutter/material.dart';

class VaultText extends StatelessWidget {
  final Vault vault;

  const VaultText(this.vault, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      vault.displayName(),
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall,
    );
  }
}
