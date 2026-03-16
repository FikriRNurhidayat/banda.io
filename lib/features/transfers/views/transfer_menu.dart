import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class TransferMenu extends StatelessWidget {
  final String id;

  const TransferMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Transfer transfer,
  ) {
    final navigator = Navigator.of(context);

    final menu = {
      "Edit": () {
        navigator.pushReplacementNamed("/transfers/$id/edit");
      },
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["transfers", transfer.id, "detail"],
            ),
          ),
        );
      },
      "Back": () {
        navigator.pop();
      },
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.read<TransferProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: transferProvider.get(id),
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

          final transfer = snapshot.data!;
          final menu = menuBuilder(context, transfer);

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
