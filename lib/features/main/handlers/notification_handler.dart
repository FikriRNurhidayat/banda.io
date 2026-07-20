import 'dart:convert';

import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/controller_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHandler {
  final GlobalKey<NavigatorState> navigator;

  NotificationHandler(this.navigator);

  navigate(String path) async {
    return navigator.currentState?.pushNamed.call(path);
  }

  handle(NotificationResponse response) async {
    try {
      if (kDebugMode) {
        print("response.payload: ${response.payload}");
        print("navigator.currentState: ${navigator.currentState}");
      }

      if (response.payload == null) {
        return;
      }

      final Map<String, dynamic> payload = jsonDecode(
        response.payload!,
      );
      final controller = Controller(
        ControllerType.parse(payload["controller_type"]),
        payload["controller_id"],
      );

      switch (controller.type) {
        case ControllerType.entry:
          return navigate("/entries/${controller.id}/detail");
        case ControllerType.obligation:
          return navigate("/obligations/${controller.id}/detail");
        case ControllerType.budget:
          return navigate("/budgets/${controller.id}/detail");
        case ControllerType.schedule:
          return navigate("/schedules/${controller.id}/detail");
        case ControllerType.fund:
          return navigate("/funds/${controller.id}/detail");
        case ControllerType.transfer:
          return navigate("/transfers/${controller.id}/detail");
        default:
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print(error);
        print(stackTrace);
      }

      return;
    }
  }
}
