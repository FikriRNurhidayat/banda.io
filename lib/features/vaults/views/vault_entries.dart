import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/vaults/widgets/vault_tile.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VaultEntries extends StatelessWidget {
  final String id;
  const VaultEntries({super.key, required this.id});

  handleMenuTap(BuildContext context) {
    Navigator.of(context).pushNamed("/vaults/$id/menu");
  }

  handleTap(BuildContext context) {
    Navigator.of(context).pushNamed("/vaults/$id/detail");
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("Vault", style: theme.textTheme.titleLarge),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            handleMenuTap(context);
          },
          icon: Icon(Icons.more_horiz),
        ),
      ],
      actionsPadding: EdgeInsets.all(8.0),
    );
  }

  entriesBuilder(BuildContext context, Vault vault) {
    final entryProvider = context.watch<EntryProvider>();
    return Expanded(
      child: FutureBuilder(
        future: entryProvider.search(
          specification: {
            "vault_in": [vault.id],
          },
        ),
        builder: futureBuilder<List<Entry>>((context, snapshot) {
          final entries = snapshot.data!;
      
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              final Entry entry = entries[index];
              return EntryTile(entry);
            },
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: vaultProvider.get(id),
        builder: futureBuilder((context, snapshot) {
          final vault = snapshot.data! as Vault;

          return Column(
            children: [
              VaultTile(vault, readOnly: true),
              Divider(height: 1),
              entriesBuilder(context, vault),
            ],
          );
        }),
      ),
    );
  }
}
