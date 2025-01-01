import 'package:checks/checks.dart';

import 'package:iterative_convex_hull/bounded.dart';
import 'package:test/test.dart';

void main() {
  group('boundedConvexHull', () {
    test('creates appropriate ranges', () {
      late PointRange range;
      boundedConvexHull([Point(0, 0), Point(0, 1), Point(0.5, 1)],
          onRangeChange: (r) => range = r);
      check(range.xMin).equals(0);
      check(range.xMax).equals(0.5);
      check(range.yMin).equals(0);
      check(range.yMax).equals(1);
    });

    test('does not trigger on internal add', () {
      bool triggered = false;
      final hull = boundedConvexHull([Point(0, 0), Point(0, 1), Point(1, 0)],
          onRangeChange: (r) => triggered = true);
      check(triggered).isTrue();
      triggered = false;
      // add internal point
      var added = hull.add(Point(0.25, 0.5));
      check(added).isNull();
      check(triggered).isFalse();
      // add new external point that doesn't change the range
      added = hull.add(Point(0.75, 0.75));
      check(added).isNotNull();
      check(triggered).isFalse();
    });

    test('triggers on external add', () {
      PointRange? range;
      final hull = boundedConvexHull([Point(0, 0), Point(0, 1), Point(0.5, 1)],
          onRangeChange: (r) => range = r);
      check(range).isNotNull();
      // add internal point
      hull.add(Point(1.5, 0.5));
      check(range).isNotNull();
      check(range!.xMax).equals(1.5);
      check(range!.xMin).equals(0);
    });

    test('triggers on relevant entry removal', () {
      PointRange? range;
      final hull = boundedConvexHull([Point(0, 0), Point(0, 1), Point(0.5, 1)],
          onRangeChange: (r) => range = r);
      check(range).isNotNull();
      check(range).equals(PointRange.fromLimits(0, 0.5, 0, 1));
      hull.remove(Point(0.5, 1));
      check(range).equals(PointRange.fromLimits(0, 0, 0, 1));
    });

    test('triggers on relevant move from boundary', () {
      PointRange? range;
      final hull = boundedConvexHull(
          [Point(0, 0), Point(0, 1), Point(0.5, 1), Point(1, 1)],
          onRangeChange: (r) => range = r);
      hull.move(Point(1, 1), Point(0.5, 1));
      check(range).equals(PointRange.fromLimits(0, 0.5, 0, 1));
    });
  });
}
