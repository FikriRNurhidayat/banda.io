import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  MainMenu({super.key});

  final List<List<String>> menu = [
    ["Entries", "/entries"],
    ["Funds", "/funds"],
    ["Information", "/info"],
    ["Journals", "/journals"],
    ["Obligations", "/obligations"],
    ["Schedules", "/schedules"],
    ["Tools", "/tools"],
    ["Transfers", "/transfers"],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ListView.builder(
          physics: AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: menu.length,
          itemBuilder: (context, index) {
            final [name, redirect] = menu[index];
            return ListTile(
              title: Text(
                name,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              onTap: () {
                Navigator.pushNamed(context, redirect);
              },
            );
          },
        ),
      ),
    );
  }
}
