class Where {
  List<String> expressions = [];
  List<dynamic> values = [];

  String get sql {
    return expressions
        .map((expression) => "($expression)")
        .join(" AND ");
  }

  add(String expression, List<dynamic> value) {
    expressions.add(expression);
    values.addAll(value);
  }

  get isNotEmpty {
    return sql.isNotEmpty;
  }

  get isEmpty {
    return sql.isEmpty;
  }
}
