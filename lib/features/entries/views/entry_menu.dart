import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class EntryMenu extends StatelessWidget {
  final String id;

  const EntryMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Entry entry,
  ) {
    final navigator = Navigator.of(context);
    final entryProvider = context.read<EntryProvider>();

    final menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["entries", entry.id, "detail"],
            ),
          ),
        );
      },
    };

    if (kDebugMode) {
      menu["Debug Reminder"] = () {
        entryProvider.debugReminder(id);
      };
    }

    menu["Back"] = () {
      navigator.pop();
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final entryProvider = context.read<EntryProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: entryProvider.get(id),
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

          final entry = snapshot.data!;
          final menu = menuBuilder(context, entry);

          return Center(
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final callback = menu.entries.elementAt(index);
                return ListTile(
                  title: Text(
                    callback.key,
                    textAlign: TextAlign.center,
                  ),
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
