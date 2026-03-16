import 'package:bandha/common/types/controller_type.dart';

class Controller {
  final String id;
  final ControllerType type;

  Controller(this.type, this.id);

  factory Controller.fromJson(Map<String, dynamic> object) {
    return Controller(
      ControllerType.parse(object["type"]),
      ControllerType.parse(object["id"]),
    );
  }

  factory Controller.pool(String id) {
    return Controller(ControllerType.pool, id);
  }

  factory Controller.commitmentPayment(String id) {
    return Controller(ControllerType.commitmentPayment, id);
  }

  factory Controller.commitment(String id) {
    return Controller(ControllerType.commitment, id);
  }

  factory Controller.budget(String id) {
    return Controller(ControllerType.budget, id);
  }

  factory Controller.transfer(String id) {
    return Controller(ControllerType.transfer, id);
  }

  factory Controller.schedule(String id) {
    return Controller(ControllerType.schedule, id);
  }

  factory Controller.entry(String id) {
    return Controller(ControllerType.entry, id);
  }

  factory Controller.purchase(String id) {
    return Controller(ControllerType.purchase, id);
  }
}
