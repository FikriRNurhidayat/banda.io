import 'package:flutter/material.dart';

class AnalyticMenu extends StatelessWidget {
  AnalyticMenu({super.key});

  final Map<String, String> menu = {
    ""
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
