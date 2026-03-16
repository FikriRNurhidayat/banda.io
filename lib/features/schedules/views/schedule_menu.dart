import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ScheduleMenu extends StatelessWidget {
  final String id;

  const ScheduleMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(BuildContext context, Schedule schedule) {
    final navigator = Navigator.of(context);
    final scheduleProvider = context.watch<ScheduleProvider>();

    final menu = {
      "Edit": () async {
        navigator.pushReplacementNamed("/schedules/$id/edit");
      },
      "Share": () async {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["schedules", schedule.id, "detail"],
            ),
          ),
        );
      },
    };

    if (schedule.canRollover) {
      menu["Rollover"] = () async {
        await scheduleProvider.rollover(schedule.id);
        navigator.pop();
      };
    }

    if (schedule.canRollback) {
      menu["Rollback"] = () async {
        await scheduleProvider.rollback(schedule.id);
        navigator.pop();
      };
    }

    menu["Back"] = () async {
      navigator.pop();
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.read<ScheduleProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: scheduleProvider.get(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("..."));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final schedule = snapshot.data!;
          final menu = menuBuilder(context, schedule);

          return Center(
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final callback = menu.entries.elementAt(index);
                return ListTile(
                  title: Text(callback.key, textAlign: TextAlign.center),
                  onTap: callback.value,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
