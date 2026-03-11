sealed class Option<T> {
  const Option();
}

class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);
}

class None<T> extends Option<T> {
  const None();
}

const none = None();
