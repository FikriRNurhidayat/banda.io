import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/widgets/date_time_text.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:bandha/features/accounts/widgets/account_text.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:flutter/material.dart';

class ScheduleTile extends StatelessWidget {
  final Schedule schedule;
  final bool readOnly;

  const ScheduleTile(this.schedule, {super.key, this.readOnly = false});

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmScheduleDeletion(context, schedule);
    }

    Navigator.pushNamed(context, "/schedules/${schedule.id}/edit");
    return false;
  }

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      readOnly ? "/schedules/${schedule.id}/detail" : "/schedules/${schedule.id}/history",
    );
  }

  Widget statusBuilder(BuildContext context) {
    final theme = Theme.of(context);
    switch (schedule.status) {
      case ScheduleStatus.pending:
        return Icon(
          Icons.hourglass_empty,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case ScheduleStatus.overdue:
        return Icon(Icons.warning, color: theme.colorScheme.primary, size: 8);
      default:
        return SizedBox(width: 8);
    }
  }

  infoBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AccountText(schedule.account),
        DateTimeText(schedule.dueAt),
        if (!isNull(schedule.note) && schedule.note!.isNotEmpty)
          Text(
            schedule.note!,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        labelsBuilder(context, schedule.labels),
      ],
    );
  }

  headerBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        Text(schedule.category.name, style: theme.textTheme.titleSmall),
        Text(schedule.cycle.label, style: theme.textTheme.labelSmall),
        Text("x${schedule.iteration.toString()}", style: theme.textTheme.labelSmall),
        statusBuilder(context),
      ],
    );
  }

  scheduleBuilder(BuildContext context) {
    return tileBuilder(
      context,
      onTap: () {
        handleTap(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [headerBuilder(context), infoBuilder(context)],
            ),
          ),
          MoneyText(schedule.amount, useSymbol: false),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: schedule.id,
      child: scheduleBuilder(context),
      dismissable: !readOnly,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
