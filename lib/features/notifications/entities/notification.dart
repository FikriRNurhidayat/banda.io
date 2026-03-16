import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/common/types/controller.dart';
import 'package:bandha/common/types/controller_type.dart';

class Notification extends Entity {
  late int id;
  final String title;
  final String body;
  final DateTime sentAt;
  final Controller controller;

  Notification({
    required this.title,
    required this.body,
    required this.sentAt,
    required this.controller,
  });

  setId(int id) {
    this.id = id;
    return this;
  }

  static int getId() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  factory Notification.create({
    required String title,
    required String body,
    required DateTime sentAt,
    required Controller controller,
  }) {
    return Notification(
      title: title,
      body: body,
      sentAt: sentAt,
      controller: controller,
    );
  }

  factory Notification.fromRow(Map<String, dynamic> row) {
    return Notification(
      title: row["title"],
      body: row["body"],
      sentAt: DateTime.parse(row["sent_at"]),
      controller: Controller(
        ControllerType.fromLabel(row["controller_type"]),
        row["controller_id"],
      ),
    ).setId(row["id"]);
  }
}
