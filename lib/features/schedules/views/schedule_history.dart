import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:bandha/features/schedules/widgets/schedule_tile.dart';
import 'package:bandha/features/schedules/widgets/entry_tile.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleHistory extends StatelessWidget {
  final String id;

  const ScheduleHistory({super.key, required this.id});

  handleMore(BuildContext context) {
    Navigator.pushNamed(context, "/schedules/$id/menu");
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Schedule History",
        style: theme.textTheme.titleMedium,
      ),

      actions: [
        IconButton(
          onPressed: () {
            handleMore(context);
          },
          icon: Icon(Icons.more_horiz),
        ),
      ],
      actionsPadding: EdgeInsets.all(8),
    );
  }

  entriesBuilder(BuildContext context, Schedule schedule) {
    final entryProvider = context.watch<EntryProvider>();

    return Expanded(
      child: FutureBuilder(
        future: entryProvider.getByController(schedule),
        builder: futureBuilder((context, snapshot) {
          final entries = snapshot.data! as List<Entry>;

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return EntryTile(entry, readOnly: true);
            },
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: scheduleProvider.get(id),
        builder: futureBuilder((context, snapshot) {
          final schedule = snapshot.data! as Schedule;

          return Column(
            children: [
              ScheduleTile(schedule, readOnly: true),
              Divider(height: 1),
              entriesBuilder(context, schedule),
            ],
          );
        }),
      ),
    );
  }
}
