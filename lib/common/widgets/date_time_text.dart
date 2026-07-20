import 'package:bandha/common/helpers/date_helper.dart';
import 'package:flutter/material.dart';

class DateTimeText extends StatelessWidget {
  final DateTime dateTime;

  const DateTimeText(this.dateTime, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      "${DateHelper.formatSimpleDate(dateTime)} at ${DateHelper.formatTime(TimeOfDay.fromDateTime(dateTime))}",
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall,
    );
  }
}
