import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/accounts/providers/account_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/accounts/widgets/account_tile.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountEntries extends StatelessWidget {
  final String id;
  const AccountEntries({super.key, required this.id});

  handleMenuTap(BuildContext context) {
    Navigator.of(context).pushNamed("/accounts/$id/menu");
  }

  handleTap(BuildContext context) {
    Navigator.of(context).pushNamed("/accounts/$id/detail");
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("Account", style: theme.textTheme.titleLarge),
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

  entriesBuilder(BuildContext context, Account account) {
    final entryProvider = context.watch<EntryProvider>();
    return Expanded(
      child: FutureBuilder(
        future: entryProvider.search(
          specification: {
            "account_in": [account.id],
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
    final accountProvider = context.watch<AccountProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: accountProvider.get(id),
        builder: futureBuilder((context, snapshot) {
          final account = snapshot.data! as Account;

          return Column(
            children: [
              AccountTile(account, readOnly: true),
              Divider(height: 1),
              entriesBuilder(context, account),
            ],
          );
        }),
      ),
    );
  }
}
