import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget splashEmpty(BuildContext context) {
  return splash(
    context,
    name: "Nihil",
    description: "Found absolutely no information to display.",
  );
}

Widget splash(
  BuildContext context, {
  required String name,
  required String description,
}) {
  final theme = Theme.of(context);

  return ListView(
    children: [
      ListTile(
        dense: true,
        title: Text(name, style: theme.textTheme.titleSmall),
        subtitle: Text(description),
      ),
    ],
  );
}

AsyncWidgetBuilder<T> futureBuilder<T>(AsyncWidgetBuilder<T> callback) {
  return (BuildContext context, AsyncSnapshot<T> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      if (kDebugMode) {
        print(snapshot.error);
        print(snapshot.stackTrace);
      }

      return splash(
        context,
        name: snapshot.error.runtimeType.toString(),
        description: snapshot.error.toString(),
      );
    }

    if (!snapshot.hasData) {
      return splashEmpty(context);
    }

    if (snapshot.data is List<dynamic>) {
      final data = snapshot.data as List<dynamic>;
      if (data.isEmpty) {
        return splashEmpty(context);
      }
    }

    return callback(context, snapshot);
  };
}
