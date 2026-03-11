bool isNull(dynamic value) {
  return value == null;
}

bool isZero(dynamic value) {
  return isNull(value) || value == 0;
}

bool isEmpty(List<dynamic>? value) {
  return isNull(value) || value!.isEmpty;
}
