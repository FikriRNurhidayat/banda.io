import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/common/helpers/error_helper.dart';
import 'package:bandha/features/funds/providers/fund_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class FundMenu extends StatelessWidget {
  final String id;

  const FundMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(BuildContext context, Fund fund) {
    final navigator = Navigator.of(context);
    final fundProvider = context.read<FundProvider>();

    final Map<String, VoidCallback> menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["funds", fund.id, "detail"],
            ),
          ),
        );
      },
      "Balance": () async {
        await fundProvider
            .sync(id)
            .catchError(
              showError(context: context, content: "Balance fund failed"),
            );
        navigator.pop();
      },
    };

    if (fund.canDispense) {
      menu["Release"] = () async {
        await fundProvider
            .release(id)
            .catchError(
              showError(context: context, content: "Release fund failed"),
            );
        navigator.pop();
      };
    }

    if (fund.status.isReleased) {
      menu["Retract"] = () async {
        await fundProvider
            .retract(id)
            .catchError(
              showError(context: context, content: "Retract fund failed"),
            );
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
    final fundProvider = context.read<FundProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: fundProvider.get(id),
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

          final fund = snapshot.data!;
          final menu = menuBuilder(context, fund);

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
