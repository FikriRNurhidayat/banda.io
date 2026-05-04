import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class VaultMenu extends StatelessWidget {
  final String id;

  const VaultMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Vault vault,
  ) {
    final navigator = Navigator.of(context);
    final vaultProvider = context.read<VaultProvider>();

    final menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["vaults", vault.id, "detail"],
            ),
          ),
        );
      },
      "Edit": () async {
        navigator.pushReplacementNamed("/vaults/${vault.id}/edit");
      },
      "Balance": () async {
        await vaultProvider.sync(vault.id);

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
    final vaultProvider = context.read<VaultProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: vaultProvider.get(id),
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

          final vault = snapshot.data!;
          final menu = menuBuilder(context, vault);

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
