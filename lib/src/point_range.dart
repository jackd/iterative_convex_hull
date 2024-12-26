import 'point.dart';
import 'value_range.dart';

class PointRange {
  final ValueRange xRange;
  final ValueRange yRange;
  const PointRange._(this.xRange, this.yRange);

  const PointRange(this.xRange, this.yRange);

  static const empty = PointRange._(ValueRange.empty, ValueRange.empty);

  factory PointRange.fromPoints(Iterable<Point> points) {
    return points
        .map((point) => PointRange.single(point))
        .fold(PointRange.empty, (a, b) => a.union(b));
  }

  factory PointRange.fromLimits(
          double xMin, double xMax, double yMin, double yMax) =>
      PointRange(
        ValueRange(xMin, xMax),
        ValueRange(yMin, yMax),
      );

  factory PointRange.fromCorners(Point bottomLeft, Point topRight) =>
      PointRange(
        ValueRange(bottomLeft.x, topRight.x),
        ValueRange(bottomLeft.y, topRight.y),
      );

  factory PointRange.union(Iterable<PointRange> ranges) =>
      ranges.fold(PointRange.empty, (a, b) => a.union(b));

  factory PointRange.single(Point point) =>
      PointRange(SingleValueRange(point.x), SingleValueRange(point.y));

  bool contains(Point point) =>
      xRange.contains(point.x) && yRange.contains(point.y);

  PointRange union(PointRange other) => PointRange(
        xRange.union(other.xRange),
        yRange.union(other.yRange),
      );

  @override
  bool operator ==(Object other) =>
      other is PointRange && xRange == other.xRange && yRange == other.yRange;

  @override
  int get hashCode => Object.hash(xRange, yRange);

  @override
  String toString() => 'PointRange(x: [$xMin, $xMax], y: [$yMin, $yMax])';

  PointRange add(Point point) =>
      PointRange(xRange.add(point.x), yRange.add(point.y));

  Point normalize(Point point) =>
      Point(xRange.normalize(point.x), yRange.normalize(point.y));

  Point get bottomLeft => Point(xRange.min, yRange.min);
  Point get bottomRight => Point(xRange.max, yRange.min);
  Point get topLeft => Point(xRange.min, yRange.max);
  Point get topRight => Point(xRange.max, yRange.max);

  double get xMin => xRange.min;
  double get xMax => xRange.max;
  double get yMin => yRange.min;
  double get yMax => yRange.max;

  bool get isEmpty => xRange is EmptyValueRange || yRange is EmptyValueRange;
  Point get single {
    final x = xRange;
    final y = yRange;
    return x is SingleValueRange && y is SingleValueRange
        ? Point(x.value, y.value)
        : throw StateError('Not a single point');
  }

  double get width => xRange.size;
  double get height => yRange.size;
}
