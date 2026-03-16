import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

showError({
  required BuildContext context,
  required String content,
  Function(Error, StackTrace)? callback,
}) {
  final messenger = ScaffoldMessenger.of(context);

  return (dynamic error, StackTrace stackTrace) {
    if (kDebugMode) {
      print(error);
      print(stackTrace);
    }

    alert(messenger, content);

    callback?.call(error, stackTrace);
  };
}
