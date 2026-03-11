import 'package:banda/features/bills/entities/bill.dart';
import 'package:banda/features/bills/providers/bill_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class BillMenu extends StatelessWidget {
  final String id;

  const BillMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(BuildContext context, Bill bill) {
    final navigator = Navigator.of(context);
    final billProvider = context.watch<BillProvider>();

    final menu = {
      "Edit": () async {
        navigator.pushReplacementNamed("/bills/$id/edit");
      },
      "Share": () async {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["bills", bill.id, "detail"],
            ),
          ),
        );
      },
    };

    if (bill.canRollover) {
      menu["Rollover"] = () async {
        await billProvider.rollover(bill.id);
        navigator.pop();
      };
    }

    if (bill.canRollback) {
      menu["Rollback"] = () async {
        await billProvider.rollback(bill.id);
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
    final billProvider = context.read<BillProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: billProvider.get(id),
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

          final bill = snapshot.data!;
          final menu = menuBuilder(context, bill);

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
