import 'dart:math';

import 'point.dart';
import 'convex_hull.dart';
import 'point_range.dart';
import 'value_range.dart';

typedef PointRangeCallback = void Function(PointRange range);

class RangeTracker {
  PointRange _range = PointRange.empty;

  set range(PointRange range) {
    if (_range != range) {
      _range = range;
      onRangeChange(range);
    }
  }

  PointRange get range => _range;

  final PointRangeCallback onRangeChange;

  RangeTracker(this.onRangeChange);

  void onEntryAdded(Entry entry) {
    range = range.add(entry.value);
  }

  void onEntryRemoved(Point point, Entry? previous) {
    if (previous == null) {
      onHullCleared();
      return;
    }
    final next = previous.next;
    var xRange = range.xRange;
    final x = point.x;
    bool changed = false;
    if (x == xRange.min) {
      changed = true;
      xRange = ValueRange(min(previous.value.x, next.value.x), xRange.max);
    } else if (x == xRange.max) {
      changed = true;
      xRange = ValueRange(xRange.min, max(previous.value.x, next.value.x));
    }
    final y = point.y;
    var yRange = range.yRange;
    if (y == yRange.min) {
      changed = true;
      yRange = ValueRange(min(previous.value.y, next.value.y), yRange.max);
    } else if (y == yRange.max) {
      changed = true;
      yRange = ValueRange(yRange.min, max(previous.value.y, next.value.y));
    }
    if (changed) {
      range = PointRange(xRange, yRange);
    }
  }

  void onHullInitialized(Entry? first) => range = first == null
      ? PointRange.empty
      : PointRange.fromPoints(first.cycle.map((e) => e.value));

  void onHullCleared() {
    range = PointRange.empty;
  }

  void onHullEvent(HullEvent event) => switch (event) {
        EntryAdded added => onEntryAdded(added.entry),
        EntryRemoved removed => onEntryRemoved(removed.point, removed.previous),
        HullCleared _ => onHullCleared(),
        HullInitialized init => onHullInitialized(init.first),
      };
}

HullEventCallback toHullEventCallback(PointRangeCallback pointRangeCallback) {
  final tracker = RangeTracker(pointRangeCallback);
  return tracker.onHullEvent;
}

HullEventCallback? _mergeCallbacks(HullEventCallback? a, HullEventCallback? b) {
  if (b == null) {
    return a;
  }
  if (a == null) {
    return b;
  }
  return (HullEvent event) {
    a(event);
    b(event);
  };
}

HullEventCallback? mergeCallbacks(
        HullEventCallback? onHullEvent, PointRangeCallback? onRangeChange) =>
    _mergeCallbacks(onHullEvent,
        onRangeChange == null ? null : toHullEventCallback(onRangeChange));

ConvexHull boundedConvexHull(Iterable<Point> points,
        {required PointRangeCallback onRangeChange,
        HullEventCallback? onHullEvent}) =>
    ConvexHull(points, onHullEvent: mergeCallbacks(onHullEvent, onRangeChange));
