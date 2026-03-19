import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/money_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/features/vaults/widgets/vault_text.dart';
import 'package:flutter/material.dart';

class PoolTile extends StatelessWidget {
  final Pool pool;
  final bool readOnly;

  const PoolTile(this.pool, {super.key, this.readOnly = false});

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      readOnly
          ? "/pools/${pool.id}/detail"
          : "/pools/${pool.id}/transactions",
    );
  }

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmPoolDeletion(context, pool);
    }

    Navigator.pushNamed(context, "/pools/${pool.id}/edit");
    return false;
  }

  statusBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return [
      if (pool.status == PoolStatus.released)
        Icon(Icons.lock, size: 8, color: theme.colorScheme.primary),
      if (pool.status != PoolStatus.released &&
          pool.balance == pool.goal)
        Icon(Icons.done_all, size: 8, color: theme.colorScheme.primary),
    ];
  }

  infoBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VaultText(pool.vault),
        Row(
          spacing: 8,
          children: [
            labelsBuilder(
              context,
              pool.labels,
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            ...statusBuilder(context),
          ],
        ),
      ],
    );
  }

  progressBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      spacing: 8,
      children: [
        SizedBox(
          height: 8,
          child: LinearProgressIndicator(
            value: pool.progress,
            backgroundColor: theme.colorScheme.surfaceContainer,
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pool.category.name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              "${(pool.completion * 100).floor()}%",
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  progressBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              MoneyHelper.normalize(pool.balance),
              style: theme.textTheme.bodySmall,
            ),
            Text("/", style: theme.textTheme.bodySmall),
            Text(
              MoneyHelper.normalize(pool.goal),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        Text(pool.status.label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  poolBuilder(BuildContext context) {
    return tileBuilder(
      context,
      onTap: () {
        handleTap(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [infoBuilder(context), progressBuilder(context)],
          ),
          progressBarBuilder(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: pool.id,
      dismissable: !readOnly,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
      child: poolBuilder(context),
    );
  }
}
