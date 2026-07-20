import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class FilterProvider extends ChangeNotifier {
  Filter? _filter;

  FilterProvider();

  void set(Filter value) {
    _filter = value;
    notifyListeners();
  }

  Filter? get() {
    return _filter;
  }

  reset() {
    _filter = null;
    notifyListeners();
  }
}
