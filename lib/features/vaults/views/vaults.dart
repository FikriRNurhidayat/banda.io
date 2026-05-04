import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/vaults/widgets/vault_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Vaults extends StatelessWidget {
  const Vaults({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultProvider = context.watch<VaultProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Vaults", style: theme.textTheme.titleLarge),
        actionsPadding: EdgeInsets.all(8),
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: vaultProvider.search(),
        builder: futureBuilder((context, snapshot) {
          final vaults = snapshot.data as List<Vault>;
          return ListView.builder(
            itemCount: vaults.length,
            itemBuilder: (BuildContext context, int index) {
              final Vault vault = vaults[index];
              return VaultTile(vault);
            },
          );
        }),
      ),
    );
  }

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/vaults/new");
      },
    );
  }
}
