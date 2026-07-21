import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/assets/entities/asset.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/assets/providers/asset_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/assets/widgets/asset_tile.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetEntries extends StatelessWidget {
  final String id;
  const AssetEntries({super.key, required this.id});

  handleMenuTap(BuildContext context) {
    Navigator.of(context).pushNamed("/assets/$id/menu");
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text("Asset", style: theme.textTheme.titleMedium),
      automaticallyImplyLeading: false,
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

  entriesBuilder(BuildContext context, Asset asset) {
    final journalProvider = context.read<JournalProvider>();
    final entryProvider = context.watch<EntryProvider>();

    return Expanded(
      child: FutureBuilder<List<Journal>>(
        future: journalProvider.search(),
        builder: (context, journalSnapshot) {
          if (!journalSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final journalIds = journalSnapshot.data!
              .where((j) => j.assetId == asset.id)
              .map((j) => j.id)
              .toList();

          if (journalIds.isEmpty) {
            return const Center(child: Text("No journals with this asset"));
          }

          return FutureBuilder(
            future: entryProvider.search(
              specification: {
                "journal_in": journalIds,
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.watch<AssetProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: assetProvider.get(id),
        builder: futureBuilder((context, snapshot) {
          final asset = snapshot.data! as Asset;

          return Column(
            children: [
              AssetTile(asset, readOnly: true),
              Divider(height: 1),
              entriesBuilder(context, asset),
            ],
          );
        }),
      ),
    );
  }
}
