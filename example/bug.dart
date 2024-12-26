import 'package:iterative_convex_hull/iterative_convex_hull.dart';

void main() {
  final hull = ConvexHull([Point(0, 0), Point(0, 1), Point(1, 0), Point(1, 1)]);
  print(hull.vertices.toList());
  hull.add(Point(0, 2));
  print(hull.vertices.toList());
  hull.add(Point(3, 0));
  print(hull.vertices.toList());
}
