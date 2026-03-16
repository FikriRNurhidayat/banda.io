import 'package:bandha/common/repositories/repository.dart';

class Service {
  Future<T> work<T>(Future<T> Function() callback) {
    return Repository.work<T>(callback);
  }
}
