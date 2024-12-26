import 'dart:math';
import 'dart:collection';

import 'package:iterative_convex_hull/src/circular_linked_list_entry.dart';

import 'point.dart';
import 'convex_hull.dart';
import 'point_range.dart';
import 'value_range.dart';

typedef PointRangeCallback = void Function(PointRange range);

/// A delegating [ConvexHull] implementation that adds [PointRange] bounds.
///
/// Also exposes [onRangeChange] to respond to changes after adding / moving /
/// removing points.
class BoundedConvexHull implements ConvexHull {
  final ConvexHull _base;
  late PointRange _pointRange;
  final PointRangeCallback? onRangeChange;
  BoundedConvexHull.fromHull(ConvexHull base, {this.onRangeChange})
      : _base = base {
    _pointRange = PointRange.fromPoints(_base.vertices);
  }

  factory BoundedConvexHull.fromPoints(Iterable<Point> points,
          {PointRangeCallback? onRangeChange}) =>
      BoundedConvexHull.fromHull(ConvexHull(points),
          onRangeChange: onRangeChange);

  @override
  bool contains(Point point) => _base.contains(point);

  @override
  UnmodifiableCircularLinkedListEntryView<Point> get first => _base.first;

  @override
  UnmodifiableCircularLinkedListEntryView<Point>? get firstOrNull =>
      _base.firstOrNull;

  @override
  bool isVertex(Point point) => _base.isVertex(point);

  @override
  UnmodifiableMapView<Point, UnmodifiableCircularLinkedListEntryView<Point>>
      get linkedVertexMap => _base.linkedVertexMap;

  @override
  Iterable<UnmodifiableCircularLinkedListEntryView<Point>> get linkedVertices =>
      _base.linkedVertices;

  @override
  bool strictlyContains(Point point) => _base.strictlyContains(point);

  @override
  Iterable<Point> get vertices => _base.vertices;

  @override
  bool get isEmpty => _base.isEmpty;

  @override
  bool get isNotEmpty => _base.isNotEmpty;

  @override
  void clear() {
    _base.clear();
    _updatePointRange(PointRange.empty);
  }

  PointRange get pointRange => _pointRange;

  void _updatePointRange(PointRange pointRange) {
    if (pointRange != _pointRange) {
      _pointRange = pointRange;
      onRangeChange?.call(_pointRange);
    }
  }

  /// Returns the new [PointRange] after removing [point] if different.
  ///
  /// Returns `null` if the [point] is not a vertex on the boundary.
  PointRange? _rangeAfterRemoval(Point point) {
    final linked = _base.linkedVertexMap[point];
    if (linked == null) {
      return null;
    }
    final isIsolated = linked.isIsolated;
    if (isIsolated) {
      return PointRange.empty;
    }
    final previous = linked.previous.value;
    final next = linked.next.value;

    // For each boundary, if `point` is on that boundary, the new boundary after
    // the point is removed will coincide with either the previous or next
    // point.
    var changed = false;
    // check xRange
    var xRange = _pointRange.xRange;
    if (point.x == _pointRange.xRange.min) {
      changed = true;
      xRange = ValueRange(min(previous.x, next.x), xRange.max);
    } else if (point.x == _pointRange.xRange.max) {
      changed = true;
      xRange = ValueRange(xRange.min, max(previous.x, next.x));
    }
    // check yRange
    var yRange = _pointRange.yRange;
    if (point.y == _pointRange.yRange.min) {
      changed = true;
      yRange = ValueRange(min(previous.y, next.y), yRange.max);
    } else if (point.y == _pointRange.yRange.max) {
      changed = true;
      yRange = ValueRange(yRange.min, max(previous.y, next.y));
    }
    return changed ? PointRange(xRange, yRange) : null;
  }

  @override
  UnmodifiableCircularLinkedListEntryView<Point>? add(Point point) {
    final added = _base.add(point);
    if (added != null) {
      _updatePointRange(_pointRange.add(point));
    }
    return added;
  }

  @override
  UnmodifiableCircularLinkedListEntryView<Point>? move(
      Point original, Point moved) {
    var range = _rangeAfterRemoval(original);
    final added = _base.move(original, moved);
    // Check if `original` was on a boundary.
    if (added != null) {
      _updatePointRange((range ?? _pointRange).add(moved));
    } else if (range != null) {
      _updatePointRange(range);
    }
    return added;
  }

  @override
  bool remove(Point point) {
    final updatedRange = _rangeAfterRemoval(point);
    final removed = _base.remove(point);
    // update ranges
    if (updatedRange != null) {
      _updatePointRange(updatedRange);
    }
    return removed;
  }
}
