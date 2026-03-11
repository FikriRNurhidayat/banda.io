final class Maybe<T> {
  final bool _isSpecified;
  final T? _value;

  const Maybe._(this._isSpecified, this._value);

  /// Not provided at all
  static const none = Maybe._(false, null);

  /// Provided (value may be null)
  const Maybe(T? value) : this._(true, value);

  bool get isNone => !_isSpecified;
  bool get isSpecified => _isSpecified;

  T? get value {
    if (!_isSpecified) {
      throw StateError('Maybe has no value (none)');
    }
    return _value;
  }
}
