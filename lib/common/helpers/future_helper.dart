import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

AsyncWidgetBuilder<T> futureBuilder<T>(AsyncWidgetBuilder<T> callback) {
  return (BuildContext context, AsyncSnapshot<T> snapshot) {
    final theme = Theme.of(context);

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      if (kDebugMode) {
        print(snapshot.error);
        print(snapshot.stackTrace);
      }

      return Center(child: Text("ERROR"));
    }

    if (!snapshot.hasData) {
      return ListView(
        children: [
          ListTile(
            dense: true,
            title: Text(
              "List is empty",
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              "Tap the add button to create your first entry.",
            ),
          ),
        ],
      );
    }

    if (snapshot.data is List<dynamic>) {
      final data = snapshot.data as List<dynamic>;
      if (data.isEmpty) {
        return ListView(
          children: [
            ListTile(
              dense: true,
              title: Text(
                "List is empty",
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                "Tap the add button to create your first entry.",
              ),
            ),
          ],
        );
      }
    }

    return callback(context, snapshot);
  };
}
