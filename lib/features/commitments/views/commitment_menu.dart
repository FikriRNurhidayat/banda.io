import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/commitments/providers/commitment_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class CommitmentMenu extends StatelessWidget {
  final String id;

  const CommitmentMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Commitment commitment,
  ) {
    final navigator = Navigator.of(context);
    final commitmentProvider = context.read<CommitmentProvider>();

    final menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["commitments", commitment.id, "detail"],
            ),
          ),
        );
      },
      "Edit": () {
        navigator.pop();
        navigator.pushNamed("/commitments/$id/edit");
      },
      "Balance": () async {
        await commitmentProvider.sync(id);
        navigator.pop();
      },
    };

    if (kDebugMode) {
      menu["Debug Reminder"] = () async {
        commitmentProvider.debugReminder(id);
      };
    }

    menu["Back"] = () async {
      navigator.pop();
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final commitmentProvider = context.read<CommitmentProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: commitmentProvider.get(id),
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

          final commitment = snapshot.data!;
          final menu = menuBuilder(context, commitment);

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
