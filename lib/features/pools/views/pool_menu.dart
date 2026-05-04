import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/common/helpers/error_helper.dart';
import 'package:bandha/features/pools/providers/pool_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class PoolMenu extends StatelessWidget {
  final String id;

  const PoolMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Pool pool,
  ) {
    final navigator = Navigator.of(context);
    final poolProvider = context.read<PoolProvider>();

    final Map<String, VoidCallback> menu = {
      "Edit": () {
        navigator.pop();
        navigator.pushNamed("/pools/$id/edit");
      },
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["pools", pool.id, "detail"],
            ),
          ),
        );
      },
      "Balance": () async {
        await poolProvider
            .sync(id)
            .catchError(
              showError(
                context: context,
                content: "Balance pool failed",
              ),
            );
        navigator.pop();
      },
    };

    if (pool.canDispense) {
      menu["Release"] = () async {
        await poolProvider
            .release(id)
            .catchError(
              showError(
                context: context,
                content: "Release pool failed",
              ),
            );
        navigator.pop();
      };
    }

    if (pool.status.isReleased) {
      menu["Retract"] = () async {
        await poolProvider
            .retract(id)
            .catchError(
              showError(
                context: context,
                content: "Retract pool failed",
              ),
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
    final poolProvider = context.read<PoolProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: poolProvider.get(id),
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

          final pool = snapshot.data!;
          final menu = menuBuilder(context, pool);

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
