import 'package:checks/checks.dart';

import 'package:iterative_convex_hull/bounded.dart';
import 'package:test/test.dart';

void main() {
  group('ConvexHull tests', () {
    test('constructor creates appropriate ranges', () {
      final hull = BoundedConvexHull.fromPoints(
          [Point(0, 0), Point(0, 1), Point(0.5, 1)]);
      final range = hull.pointRange;
      check(range.xMin).equals(0);
      check(range.xMax).equals(0.5);
      check(range.yMin).equals(0);
      check(range.yMax).equals(1);
    });

    test('redundant add does not trigger onRangeChange', () {
      var triggered = false;
      final hull = BoundedConvexHull.fromPoints(
          [Point(0, 0), Point(0, 1), Point(1, 1)],
          onRangeChange: (_) => triggered = true);
      check(triggered).isFalse();
      // add internal point
      hull.add(Point(0.25, 0.5));
      check(triggered).isFalse();
      // add new vertex that doesn't change the range
      hull.add(Point(1, 0));
      check(triggered).isFalse();
    });

    test('add triggers onRangeChange', () {
      var triggered = false;
      final hull = BoundedConvexHull.fromPoints(
          [Point(0, 0), Point(0, 1), Point(0.5, 1)],
          onRangeChange: (_) => triggered = true);
      check(triggered).isFalse();
      // add internal point
      hull.add(Point(1.5, 0.5));
      check(triggered).isTrue();
      check(hull.pointRange.xMax).equals(1.5);
      check(hull.pointRange.xMin).equals(0);
    });

    test('remove triggers onRangeChange', () {
      var triggered = false;
      final hull = BoundedConvexHull.fromPoints(
          [Point(0, 0), Point(0, 1), Point(0.5, 1)],
          onRangeChange: (_) => triggered = true);
      check(hull.pointRange).equals(PointRange.fromLimits(0, 0.5, 0, 1));
      hull.remove(Point(0.5, 1));
      check(triggered).isTrue();
      check(hull.pointRange).equals(PointRange.fromLimits(0, 0, 0, 1));
    });

    test('redundant move to interior does not trigger onRangeChange', () {
      var triggered = false;
      final hull = BoundedConvexHull.fromPoints(
          [Point(0, 0), Point(0, 1), Point(1, 0.25), Point(1, 1)],
          onRangeChange: (_) => triggered = true);
      check(hull.pointRange).equals(PointRange.fromLimits(0, 1, 0, 1));
      check(hull.linkedVertexMap).length.equals(4);
      hull.move(Point(1, 0.25), Point(0.2, 0.25));
      check(hull.linkedVertexMap).length.equals(3);
      check(triggered).isFalse();
      check(hull.pointRange).equals(PointRange.fromLimits(0, 1, 0, 1));
    });

    test('move from boundary triggers onRangeChange', () {
      var triggered = false;
      final hull = BoundedConvexHull.fromPoints(
          [Point(0, 0), Point(0, 1), Point(1, 1)],
          onRangeChange: (_) => triggered = true);
      hull.move(Point(1, 1), Point(0.5, 1));
      check(triggered).isTrue();
      check(hull.pointRange).equals(PointRange.fromLimits(0, 0.5, 0, 1));
    });
  });
}
