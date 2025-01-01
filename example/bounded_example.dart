import 'package:iterative_convex_hull/bounded.dart';

void main() {
  late PointRange range;
  final hull = boundedConvexHull(
      [Point(0, 0), Point(0, 1), Point(1, 0), Point(1, 1), Point(0.5, 0.5)],
      onRangeChange: (r) {
    range = r;
    print('Range changed to $r');
  });

  print(range); // PointRange(x: [0.0, 1.0], y: [0.0, 1.0])
  hull.add(Point(0.5, 0.5)); // no print
  hull.add(Point(2, 0));
  // prints 'Range changed to PointRange(x: [0.0, 2.0], y: [0.0, 1.0])'
  print(range);
}
