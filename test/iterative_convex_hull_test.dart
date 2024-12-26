import 'package:checks/checks.dart';

import 'package:iterative_convex_hull/iterative_convex_hull.dart';
import 'package:test/test.dart';

void main() {
  group('ConvexHull tests', () {
    const bottomLeft = Point(0, 0);
    const bottomRight = Point(1, 0);
    const topRight = Point(1, 1);
    const topLeft = Point(0, 1);
    const center = Point(0.5, 0.5);
    final vertices = [
      bottomLeft,
      bottomRight,
      topRight,
      topLeft,
    ];

    test('constructor removes interior points', () {
      final hull = ConvexHull([...vertices, center]);
      final checker = check(hull.vertices)..length.equals(4);
      for (final vertex in vertices) {
        checker.contains(vertex);
      }
    });

    test('isVertex', () {
      final hull = ConvexHull(vertices);
      for (final vertex in vertices) {
        check(hull.isVertex(vertex)).isTrue();
      }
    });

    test('add internal point', () {
      final hull = ConvexHull(vertices);
      final added = hull.add(Point(0.25, 0.25));
      check(added).isNull();
      check(hull.vertices).length.equals(4);
    });

    test('add new vertex simple', () {
      final hull = ConvexHull(vertices);
      check(hull.vertices).length.equals(4);
      const p = Point(1.5, 0.5);
      final added = hull.add(p);
      check(added).isNotNull();
      check(hull.vertices).length.equals(5);
      check(hull.isVertex(p)).isTrue();
    });

    test('add new vertex tricky', () {
      final hull = ConvexHull(vertices);
      const p = Point(2, 2);
      final added = hull.add(p);
      check(added).isNotNull();
      check(hull.vertices).length.equals(4);
      check(hull.isVertex(topRight)).isFalse();
      check(hull.isVertex(p)).isTrue();
    });

    test('remove vertex', () {
      final hull = ConvexHull(vertices);
      final removed = hull.remove(topRight);
      check(removed).isTrue();
      check(hull.vertices).length.equals(3);
      check(hull.isVertex(topRight)).isFalse();
      check(hull.isVertex(topLeft)).isTrue();
      check(hull.isVertex(bottomRight)).isTrue();
      check(hull.isVertex(bottomLeft)).isTrue();
    });

    test('move', () {
      const centerRight = Point(1.1, 0.5);
      final hull = ConvexHull([...vertices, centerRight]);
      check(hull.vertices).length.equals(5);
      check(hull.isVertex(centerRight)).isTrue();
      const moreTopRight = Point(1.1, 1.1);
      var moved = hull.move(topRight, moreTopRight);
      check(moved).isNotNull();
      check(hull.isVertex(moreTopRight)).isTrue();
      check(hull.isVertex(topRight)).isFalse();
      check(hull.isVertex(centerRight)).isTrue();
      check(hull.vertices).length.equals(5);
      // move back
      moved = hull.move(moreTopRight, topRight);
      check(moved).isNotNull();
      check(hull.isVertex(moreTopRight)).isFalse();
      check(hull.isVertex(topRight)).isTrue();
      check(hull.isVertex(centerRight)).isTrue();
      check(hull.vertices).length.equals(5);
      // add most
      const mostTopRight = Point(2, 2);
      hull.move(topRight, mostTopRight);
      check(hull.isVertex(mostTopRight)).isTrue();
      check(hull.isVertex(topRight)).isFalse();
      check(hull.isVertex(centerRight)).isFalse();
      check(hull.vertices).length.equals(4);

      moved = hull.move(mostTopRight, Point(0.1, 0.1));
      check(moved).isNull();
      check(hull.vertices).length.equals(3);
    });

    test('add colinear', () {
      void checkReplace(List<Point> vertices, Point replacing, Point beyond) {
        final hull = ConvexHull(vertices);
        final originalVertices = hull.vertices.toList();
        var beyondVertices =
            vertices.map((v) => v == replacing ? beyond : v).toSet();
        var added = hull.add(beyond);
        check(added).isNotNull();
        check(hull.vertices.toSet()).deepEquals(beyondVertices);
        // move back to original
        var moved = hull.move(beyond, replacing);
        check(moved).isNotNull();
        check(hull.vertices.toList()).deepEquals(originalVertices);
        // ensure move works as well
        moved = hull.move(replacing, beyond);
        check(moved).isNotNull();
        check(hull.vertices.toSet()).deepEquals(beyondVertices);
      }

      // colinearBeyond
      checkReplace(vertices, bottomRight, Point(2, 0));
      checkReplace(vertices, topRight, Point(1, 2));
      checkReplace(vertices, topLeft, Point(-1, 1));
      checkReplace(vertices, bottomLeft, Point(0, -1));

      // colinearBefore
      checkReplace(vertices, bottomLeft, Point(-1, 0));
      checkReplace(vertices, bottomRight, Point(1, -1));
      checkReplace(vertices, topRight, Point(2, 1));
      checkReplace(vertices, topLeft, Point(0, 2));

      // colinearBetween
      final hull = ConvexHull(vertices);
      final originalVertices = hull.vertices.toList();
      for (final point in [
        Point(0.5, 0),
        Point(1, 0.5),
        Point(0.5, 1),
        Point(0, 0.5)
      ]) {
        final added = hull.add(point);
        check(added).isNull();
        check(hull.vertices.toList()).deepEquals(originalVertices);
      }
    });
  });
}
