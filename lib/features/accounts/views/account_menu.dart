import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/accounts/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class AccountMenu extends StatelessWidget {
  final String id;

  const AccountMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Account account,
  ) {
    final navigator = Navigator.of(context);
    final accountProvider = context.read<AccountProvider>();

    final menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["accounts", account.id, "detail"],
            ),
          ),
        );
      },
      "Edit": () async {
        navigator.pushReplacementNamed("/accounts/${account.id}/edit");
      },
      "Balance": () async {
        await accountProvider.sync(account.id);

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
    final accountProvider = context.read<AccountProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: accountProvider.get(id),
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

          final account = snapshot.data!;
          final menu = menuBuilder(context, account);

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
