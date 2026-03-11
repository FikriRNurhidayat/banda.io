import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  MainMenu({super.key});

  final Map<String, String> menu = {
    "Accounts": "/accounts",
    "Bills": "/bills",
    "Entries": "/entries",
    "Funds": "/funds",
    "Info": "/info",
    "Loans": "/loans",
    "Tools": "/tools",
    "Transfers": "/transfers",
    // "Budgets": "/budgets",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView.builder(
          physics: AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: menu.length,
          itemBuilder: (context, index) {
            final item = menu.entries.elementAt(index);
            return ListTile(
              title: Text(item.key, textAlign: TextAlign.center),
              onTap: () {
                Navigator.pushNamed(context, item.value);
              },
            );
          },
        ),
      ),
    );
  }
}
