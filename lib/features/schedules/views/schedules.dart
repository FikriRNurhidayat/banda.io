import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:bandha/features/schedules/widgets/schedule_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Schedules extends StatelessWidget {
  const Schedules({super.key});

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/schedules/new");
      },
    );
  }

  PreferredSizeWidget appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        "Schedules",
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      actionsPadding: EdgeInsets.all(8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: scheduleProvider.search(),
        builder: futureBuilder((context, snapshot) {
          final schedules = snapshot.data! as List<Schedule>;

          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return ScheduleTile(schedule);
            },
          );
        }),
      ),
    );
  }
}
