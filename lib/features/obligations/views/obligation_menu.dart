import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/features/obligations/providers/obligation_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ObligationMenu extends StatelessWidget {
  final String id;

  const ObligationMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Obligation obligation,
  ) {
    final navigator = Navigator.of(context);
    final obligationProvider = context.read<ObligationProvider>();

    final menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["obligations", obligation.id, "detail"],
            ),
          ),
        );
      },
      "Edit": () {
        navigator.pop();
        navigator.pushNamed("/obligations/$id/edit");
      },
      "Balance": () async {
        await obligationProvider.sync(id);
        navigator.pop();
      },
    };

    if (kDebugMode) {
      menu["Debug Reminder"] = () async {
        obligationProvider.debugReminder(id);
      };
    }

    menu["Back"] = () async {
      navigator.pop();
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final obligationProvider = context.read<ObligationProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: obligationProvider.get(id),
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

          final obligation = snapshot.data!;
          final menu = menuBuilder(context, obligation);

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
