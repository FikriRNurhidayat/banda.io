import 'package:banda/common/types/controller_type.dart';

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

  factory Controller.fund(String id) {
    return Controller(ControllerType.fund, id);
  }

  factory Controller.loanPayment(String id) {
    return Controller(ControllerType.loanPayment, id);
  }

  factory Controller.loan(String id) {
    return Controller(ControllerType.loan, id);
  }

  factory Controller.budget(String id) {
    return Controller(ControllerType.budget, id);
  }

  factory Controller.transfer(String id) {
    return Controller(ControllerType.transfer, id);
  }

  factory Controller.bill(String id) {
    return Controller(ControllerType.bill, id);
  }

  factory Controller.entry(String id) {
    return Controller(ControllerType.entry, id);
  }

  factory Controller.purchase(String id) {
    return Controller(ControllerType.purchase, id);
  }
}
