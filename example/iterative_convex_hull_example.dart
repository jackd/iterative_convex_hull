import 'package:iterative_convex_hull/iterative_convex_hull.dart';

void main() {
  const bottomLeft = Point(0, 0);
  const bottomRight = Point(1, 0);
  const topRight = Point(1, 1);
  const topLeft = Point(0, 1);
  const center = Point(0.5, 0.5);
  final hull = ConvexHull([
    bottomLeft,
    bottomRight,
    topRight,
    topLeft,
    center,
  ]);
  assert(hull.vertices.length == 4);
  assert(!hull.isVertex(center));
  assert(hull.isVertex(topRight));
  assert(hull.contains(topRight));
  assert(!hull.strictlyContains(topRight));

  // add farTopRight, which will consume original topRight
  const farTopRight = Point(2, 2);
  final added = hull.add(farTopRight);
  assert(added != null);
  assert(hull.vertices.length == 4);
  assert(hull.isVertex(farTopRight));
  assert(!hull.isVertex(topRight));

  // add centerTop, which will increase the vertex count.
  const centerTop = Point(0.5, 2);
  final added2 = hull.add(centerTop);
  assert(added2 != null);
  assert(hull.vertices.length == 5);
  assert(hull.isVertex(centerTop));

  // try to add an extra point inside the hull.
  const differentInternal = Point(0.25, 0.25);
  final added3 = hull.add(differentInternal);
  assert(added3 == null);
  assert(hull.vertices.length == 5);
  assert(hull.contains(differentInternal));

  final removed = hull.remove(differentInternal);
  assert(!removed);
  assert(hull.vertices.length == 5);

  final removed2 = hull.remove(Point(0.5, 2)); // center top
  assert(removed2);
  assert(hull.vertices.length == 4);

  print('Example completed');
}
