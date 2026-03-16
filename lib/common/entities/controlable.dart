import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/common/types/controller.dart';

abstract class Controlable extends Entity {
  abstract final String id;

  Controller toController();
}
