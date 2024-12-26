import 'package:collection/collection.dart';
import 'package:convex_hull/convex_hull.dart';

import 'circular_linked_list_entry.dart';
import 'point.dart';

class _Edge {
  final CircularLinkedListEntry<Point> start;
  CircularLinkedListEntry<Point> get end => start.next;

  const _Edge.from(this.start);
  factory _Edge.to(CircularLinkedListEntry<Point> end) =>
      _Edge.from(end.previous);

  @override
  String toString() => 'Edge(${start.value} -> ${end.value})';

  Point get direction => end.value - start.value;

  _Edge get previous => _Edge.to(start);

  _Edge get next => _Edge.from(end);

  double signedArea(Point point) => direction.cross(point - start.value);

  ComparedState comparedTo(Point point) {
    final area = signedArea(point);
    if (area == 0) {
      final sp = point - start.value;
      final se = end.value - start.value;
      if (sp.dot(se) < 0) {
        return ComparedState.colinearBefore;
      }
      return sp.squaredLength() > se.squaredLength()
          ? ComparedState.colinearBeyond
          : ComparedState.colinearBetween;
    }
    return area < 0 ? ComparedState.rightOf : ComparedState.leftOf;
  }

  @override
  bool operator ==(Object other) => other is _Edge && other.start == start;

  @override
  int get hashCode => start.hashCode;
}

enum ComparedState {
  colinearBefore, // point is on the line, before the start of the segment
  colinearBetween, // point is on the line, between the start and end
  colinearBeyond, // point is on the line, after the end of the segment
  leftOf, // point is left of / inside
  rightOf; // point is right of / outside
}

int _compareEntries(
    CircularLinkedListEntry<Point> a, CircularLinkedListEntry<Point> b) {
  final xCompare = a.value.x.compareTo(b.value.x);
  return xCompare == 0 ? a.value.y.compareTo(b.value.y) : xCompare;
}

class ConvexHull {
  late final Map<Point, CircularLinkedListEntry<Point>> _entries;
  CircularLinkedListEntry<Point>? _first;
  UnmodifiableCircularLinkedListEntryView<Point>? get firstOrNull => _first;
  UnmodifiableCircularLinkedListEntryView<Point> get first => firstOrNull!;

  /// An unmodifiable view of the unmodifiable list entries, keyed by value.
  UnmodifiableMapView<Point, UnmodifiableCircularLinkedListEntryView<Point>>
      get linkedVertexMap => UnmodifiableMapView(_entries);

  ConvexHull(Iterable<Point> points) {
    if (points.isEmpty) {
      _entries = {};
    } else {
      points = convexHull(points, x: (p) => p.x, y: (p) => p.y);
      _first = CircularLinkedListEntry.fromValues(points);
      _entries =
          Map.fromEntries(_first!.entries.map((e) => MapEntry(e.value, e)));
    }
  }

  Iterable<_Edge> get _edges => _first?.entries.map(_Edge.from) ?? const [];

  Iterable<Point> get vertices => linkedVertices.map((e) => e.value);

  /// The vertices of the convex hull in counter-clockwise order
  Iterable<UnmodifiableCircularLinkedListEntryView<Point>> get linkedVertices =>
      _first?.entries ?? const [];

  /// Returns `true` if the point is a vertex of the hull.
  bool isVertex(Point point) => _entries.containsKey(point);

  /// Returns `true` if the point is in the hull (interior / boundary).
  bool contains(Point point) => _edges.every((e) => e.signedArea(point) >= 0);

  /// Returns `true` if the point is in the interior of the hull.
  bool strictlyContains(Point point) =>
      _edges.every((e) => e.signedArea(point) > 0);

  bool get isEmpty => _first == null;

  bool get isNotEmpty => !isEmpty;

  void clear() {
    _entries.clear();
    _first = null;
  }

  void _split(
      CircularLinkedListEntry<Point> a, CircularLinkedListEntry<Point> b) {
    final split = CircularLinkedListEntry.split(a, b);
    if (split != null) {
      for (final e in split.entries) {
        _entries.remove(e.value);
        if (e == _first) {
          _first = null;
        }
      }
    }
    _first ??= _compareEntries(a, b) < 0 ? a : b;
  }

  /// Add an entry, updating [_entries] and possibly [_first]
  CircularLinkedListEntry<Point> _addEntry(
      CircularLinkedListEntry<Point> entry) {
    final point = entry.value;
    _entries[point] = entry;
    // maybe replace first
    final first = _first;
    if (first == null || _compareEntries(entry, first) < 0) {
      _first = entry;
    }
    return entry;
  }

  /// Remove an entry, updating [_entries] and possibly [_first], and unlinks
  /// it from neighboring entries.
  void _removeEntry(CircularLinkedListEntry<Point> entry) {
    final removed = _entries.remove(entry.value);
    assert(removed == entry);
    if (entry == _first) {
      if (entry.isIsolated) {
        _first = null;
      } else {
        _first = _compareEntries(entry.previous, entry.next) < 0
            ? entry.previous
            : entry.next;
      }
    }
    entry.unlink();
  }

  CircularLinkedListEntry<Point>? _addNear(Point point, _Edge nearby) {
    var startEdge = nearby.next;
    CircularLinkedListEntry<Point>? newPrevious;
    // go backwards until point is left of the edge
    switch (nearby.comparedTo(point)) {
      case ComparedState.colinearBetween:
        return null;
      case ComparedState.leftOf:
        // search forward for newPrevious until colinearBeyond / rightOf
        // then use start
        var edge = nearby.next;
        while (newPrevious == null) {
          switch (edge.comparedTo(point)) {
            case ComparedState.colinearBetween:
              return null;
            case ComparedState.rightOf:
            case ComparedState.colinearBeyond:
              newPrevious = edge.start;
              startEdge = edge.next;
              break;
            case ComparedState.leftOf:
              edge = edge.next;
              if (edge == nearby) {
                // everything is leftOf, so point is inside
                return null;
              }
            case ComparedState.colinearBefore:
              throw StateError('Should not be possible');
          }
        }
      case ComparedState.colinearBefore:
        newPrevious = nearby.previous.start;
      case ComparedState.colinearBeyond:
        newPrevious = nearby.start;
        startEdge = nearby.next;
      case ComparedState.rightOf:
        // search backward for newPrevious until leftOf / colinearBefore
        var edge = nearby.previous;
        while (newPrevious == null) {
          switch (edge.comparedTo(point)) {
            case ComparedState.colinearBetween:
              return null;
            case ComparedState.leftOf:
              newPrevious = edge.end;
            case ComparedState.colinearBefore:
            case ComparedState.rightOf:
              edge = edge.previous;
            case ComparedState.colinearBeyond:
              newPrevious = edge.start;
          }
        }
    }
    CircularLinkedListEntry<Point>? newNext;
    var edge = startEdge;
    while (newNext == null) {
      // search forward until first leftOf
      switch (edge.comparedTo(point)) {
        case ComparedState.colinearBetween:
          return null;
        case ComparedState.rightOf:
        case ComparedState.colinearBefore:
          edge = edge.next;
          if (edge == startEdge) {
            throw StateError('Should not be possible');
          }
        case ComparedState.leftOf:
          newNext = edge.start;
        case ComparedState.colinearBeyond:
          throw StateError('Should not be possible');
      }
    }
    // search forward from startEdge
    _split(newPrevious, newNext);
    final entry = newPrevious.insertAfter(point);
    return _addEntry(entry);
  }

  /// Add a point to the hull.
  ///
  /// Returns `true` if the point is a vertex of the new hull, or `false` if
  /// the point was already inside (in which case the hull is unchanged).
  UnmodifiableCircularLinkedListEntryView<Point>? add(Point point) {
    // based on slide 1
    // https://www.cs.jhu.edu/~misha/Spring16/07.pdf

    final first = _first;
    // when number of vertices == 0
    if (first == null) {
      final entry = CircularLinkedListEntry.isolated(point);
      return _addEntry(entry);
    }
    // when number of vertices == 1
    if (first.isIsolated) {
      if (first.value == point) {
        return null;
      }
      final entry = first.insertAfter(point);
      _addEntry(entry);
      return entry;
    }
    // number of vertices at least 2
    return _addNear(point, _Edge.from(first));
  }

  /// Attempts to remove a vertex from the hull.
  ///
  /// Returns `true` if [point] is a vertex of the hull and was removed,
  /// otherwise `false` (in which case the hull is unchanged).
  bool remove(Point point) {
    final entry = _entries[point];
    if (entry == null) {
      return false;
    }
    _removeEntry(entry);
    return true;
  }

  /// Move a point from [original] to [moved].
  ///
  /// Returns `true` if [moved] is a vertex of the new hull.
  UnmodifiableCircularLinkedListEntryView<Point>? move(
      Point original, Point moved) {
    final entry = _entries[original];
    if (entry == null) {
      throw ArgumentError('original must be in the hull');
    }
    if (entry.isIsolated) {
      _removeEntry(entry);
      return _addEntry(CircularLinkedListEntry.isolated(moved));
    }
    final previous = entry.previous;
    _removeEntry(entry);
    return _addNear(moved, _Edge.from(previous));
  }
}
