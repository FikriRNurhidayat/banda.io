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
        title: Text(
          "Vaults",
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actionsPadding: EdgeInsets.all(8),
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: vaultProvider.search(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("...", style: theme.textTheme.bodySmall));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Icon(
                Icons.dashboard_customize_outlined,
                size: theme.textTheme.displayLarge!.fontSize,
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (BuildContext context, int index) {
              final Vault vault = snapshot.data![index];
              return VaultTile(vault);
            },
          );
        },
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
