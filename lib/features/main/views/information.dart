import 'package:flutter/material.dart';

class Information extends StatelessWidget {
  Information({super.key});

  final info = [
    {"title": "Delete", "subtitle": "Swipe right to left to delete."},
    {"title": "Edit", "subtitle": "Swipe left to right to edit."},
    {"title": "See", "subtitle": "Tap to see the detail."},
    {"title": "Readonly", "subtitle": "Lock icon means readonly."},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Info", style: theme.textTheme.titleLarge),
      ),
      body: ListView.builder(
        itemCount: info.length,
        itemBuilder: (context, index) {
          final i = info[index];

          return ListTile(
            title: Text(i["title"]!, style: theme.textTheme.titleSmall),
            subtitle: Text(
              i["subtitle"]!,
              style: theme.textTheme.bodySmall,
            ),
            dense: true,
          );
        },
      ),
    );
  }
}
