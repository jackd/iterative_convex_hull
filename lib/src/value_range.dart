import 'dart:math' as math;

sealed class ValueRange {
  factory ValueRange(double min, double max) {
    if (min.isNaN || max.isNaN) {
      if (min.isNaN != max.isNaN) {
        throw ArgumentError.value(
            (min, max), 'min', 'min and max must be both NaN');
      }
      return ValueRange.empty;
    }
    if (min > max) {
      return ValueRange.empty;
    }
    if (min == max) {
      return SingleValueRange(min);
    }
    return DoubleValueRange(min, max);
  }

  factory ValueRange.fromIterable(Iterable<double> values) =>
      values.fold(ValueRange.empty, (a, b) => a.add(b));

  static const empty = EmptyValueRange._();

  bool contains(double value);

  ValueRange union(ValueRange other);

  ValueRange add(double value);

  double get min;

  double get max;

  double get size;

  double normalize(double value);
}

final class DoubleValueRange implements ValueRange {
  @override
  final double min;

  @override
  final double max;

  const DoubleValueRange(this.min, this.max) : assert(min < max);

  @override
  double get size => max - min;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  bool operator ==(Object other) =>
      other is DoubleValueRange && min == other.min && max == other.max;

  @override
  bool contains(double value) => min <= value && value <= max;

  @override
  String toString() => 'ValueRange($min, $max)';

  @override
  ValueRange union(ValueRange other) {
    switch (other) {
      case DoubleValueRange other:
        return DoubleValueRange(
            math.min(min, other.min), math.max(max, other.max));
      default:
        return other.union(this);
    }
  }

  @override
  ValueRange add(double value) => value < min
      ? DoubleValueRange(value, max)
      : value > max
          ? DoubleValueRange(min, value)
          : this;

  @override
  double normalize(double value) => (value - min) / size;
}

final class SingleValueRange implements ValueRange {
  final double value;

  const SingleValueRange(this.value);

  @override
  double get min => value;

  @override
  double get max => value;

  @override
  double get size => 0;

  @override
  bool contains(double value) => value == this.value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is SingleValueRange && value == other.value;

  @override
  String toString() => 'SingleValueRange($value)';

  @override
  ValueRange union(ValueRange other) => other.add(value);

  @override
  ValueRange add(double value) => value == this.value
      ? this
      : value < this.value
          ? DoubleValueRange(value, this.value)
          : DoubleValueRange(this.value, value);

  @override
  double normalize(double value) => value < this.value
      ? -double.infinity
      : value > this.value
          ? double.infinity
          : double.nan;
}

final class EmptyValueRange implements ValueRange {
  const EmptyValueRange._();

  @override
  bool contains(double value) => false;

  @override
  ValueRange union(ValueRange other) => other;

  @override
  SingleValueRange add(double value) => SingleValueRange(value);

  @override
  double get min => double.nan;

  @override
  double get max => double.nan;

  @override
  double get size => double.nan;

  @override
  double normalize(double value) => double.nan;

  @override
  String toString() => 'EmptyValueRange';
}
