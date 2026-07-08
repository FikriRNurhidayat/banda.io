import 'package:bandha/features/settlements/entities/settlement.dart';
import 'package:bandha/features/settlements/providers/settlement_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettlementMenu extends StatelessWidget {
  final String id;

  const SettlementMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Settlement settlement,
  ) {
    final navigator = Navigator.of(context);
    final settlementProvider = context.read<SettlementProvider>();

    final menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["settlements", settlement.id, "detail"],
            ),
          ),
        );
      },
      "Edit": () {
        navigator.pop();
        navigator.pushNamed("/settlements/$id/edit");
      },
      "Balance": () async {
        await settlementProvider.sync(id);
        navigator.pop();
      },
    };

    if (kDebugMode) {
      menu["Debug Reminder"] = () async {
        settlementProvider.debugReminder(id);
      };
    }

    menu["Back"] = () async {
      navigator.pop();
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final settlementProvider = context.read<SettlementProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: settlementProvider.get(id),
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

          final settlement = snapshot.data!;
          final menu = menuBuilder(context, settlement);

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
