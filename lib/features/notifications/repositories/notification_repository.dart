import 'package:banda/features/notifications/entities/notification.dart';
import 'package:banda/common/repositories/repository.dart';
import 'package:banda/common/types/controller.dart';

class NotificationRepository extends Repository {
  final WithArgs withArgs;

  NotificationRepository(super.db, {WithArgs? withArgs})
    : withArgs = withArgs ?? {};

  Future<Notification?> getByController(Controller controller) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT notifications.* FROM notifications WHERE notifications.controller_id = ? AND notifications.controller_type = ?",
      [controller.id, controller.type.label],
    );

    return rows
        .map((row) => Notification.fromRow(row))
        .toList()
        .firstOrNull;
  }

  Future<void> save(Notification notification) async {
    final client = await getClient();
    final rows = client.select(
      "INSERT INTO notifications (title, body, sent_at, controller_id, controller_type) VALUES (?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET title = excluded.title, body = excluded.body, sent_at = excluded.sent_at, controller_id = excluded.controller_id, controller_type = excluded.controller_type RETURNING id",
      [
        notification.title,
        notification.body,
        notification.sentAt.toIso8601String(),
        notification.controller.id,
        notification.controller.type.label,
      ],
    );

    return notification.setId(rows.first['id']);
  }

  Future<void> delete(int id) async {
    final client = await getClient();
    client.execute("DELETE FROM notifications WHERE id = ?", [id]);
  }
}
