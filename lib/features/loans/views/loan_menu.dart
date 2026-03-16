import 'package:bandha/features/loans/entities/loan.dart';
import 'package:bandha/features/loans/providers/loan_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class LoanMenu extends StatelessWidget {
  final String id;

  const LoanMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(BuildContext context, Loan loan) {
    final navigator = Navigator.of(context);
    final loanProvider = context.read<LoanProvider>();

    final menu = {
      "Share": () {
        SharePlus.instance.share(
          ShareParams(
            uri: Uri(
              scheme: "app",
              host: "bandha.id",
              pathSegments: ["loans", loan.id, "detail"],
            ),
          ),
        );
      },
      "Edit": () {
        navigator.pop();
        navigator.pushNamed("/loans/$id/edit");
      },
      "Balance": () async {
        await loanProvider.sync(id);
        navigator.pop();
      },
    };

    if (kDebugMode) {
      menu["Debug Reminder"] = () async {
        loanProvider.debugReminder(id);
      };
    }

    menu["Back"] = () async {
      navigator.pop();
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = context.read<LoanProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: loanProvider.get(id),
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

          final loan = snapshot.data!;
          final menu = menuBuilder(context, loan);

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
