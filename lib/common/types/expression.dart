class Expression {
  final Operator operator;
  String? field;
  dynamic value;
  List<Expression>? rules;

  Expression({
    required this.operator,
    this.field,
    this.value,
    this.rules,
  });
}

enum Operator {
  notEquals("ne"),
  equals("eq"),
  greaterThan("gt"),
  greaterThanOrEqual("gte"),
  lesserThan("lt"),
  lesserThanOrEqual("lte"),
  and("and"),
  or("or"),
  not("not");

  final String value;
  const Operator(this.value);
}
