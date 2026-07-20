import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class JournalMenu extends StatelessWidget {
  final String id;

  const JournalMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Journal journal,
  ) {
    final navigator = Navigator.of(context);
    final journalProvider = context.read<JournalProvider>();

    final menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["journals", journal.id, "detail"],
            ),
          ),
        );
      },
      "Edit": () async {
        navigator.pushReplacementNamed("/journals/${journal.id}/edit");
      },
      "Balance": () async {
        await journalProvider.sync(journal.id);

        navigator.pop();
      },
      "Back": () {
        navigator.pop();
      },
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final journalProvider = context.read<JournalProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: journalProvider.get(id),
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

          final journal = snapshot.data!;
          final menu = menuBuilder(context, journal);

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
