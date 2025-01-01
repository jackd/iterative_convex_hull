import 'package:collection/collection.dart';
import 'package:convex_hull/convex_hull.dart';

import 'circular_linked_list_entry.dart';
import 'point.dart';

typedef Entry = UnmodifiableCircularLinkedListEntryView<Point>;

sealed class HullEvent {
  static const cleared = HullCleared._();
}

class EntryAdded implements HullEvent {
  final Entry entry;
  const EntryAdded(this.entry);
}

class EntryRemoved implements HullEvent {
  final Point point;
  final Entry? previous; // previous entry prior to removal
  const EntryRemoved(this.point, this.previous);
}

class HullCleared implements HullEvent {
  const HullCleared._();
}

class HullInitialized implements HullEvent {
  final Entry? first;
  const HullInitialized(this.first);
}

typedef HullEventCallback = void Function(HullEvent event);

HullEventCallback hullEventCallback({
  void Function(Entry? first)? onInitialized,
  void Function(Entry entry)? onAdded,
  void Function(Point point, Entry? previous)? onRemoved,
  void Function()? onCleared,
}) =>
    (event) => switch (event) {
          HullCleared _ => onCleared?.call(),
          HullInitialized init => onInitialized?.call(init.first),
          EntryAdded added => onAdded?.call(added.entry),
          EntryRemoved removed =>
            onRemoved?.call(removed.point, removed.previous),
        };

class _Edge {
  final _MutableEntry start;
  _MutableEntry get end => start.next;

  const _Edge.from(this.start);
  factory _Edge.to(_MutableEntry end) => _Edge.from(end.previous);

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

typedef _MutableEntry = CircularLinkedListEntry<Point>;

enum ComparedState {
  colinearBefore, // point is on the line, before the start of the segment
  colinearBetween, // point is on the line, between the start and end
  colinearBeyond, // point is on the line, after the end of the segment
  leftOf, // point is left of / inside
  rightOf; // point is right of / outside
}

int _compareEntries(_MutableEntry a, _MutableEntry b) {
  final xCompare = a.value.x.compareTo(b.value.x);
  return xCompare == 0 ? a.value.y.compareTo(b.value.y) : xCompare;
}

class ConvexHull {
  final HullEventCallback? onHullEvent;
  late final Map<Point, _MutableEntry> _entries;
  _MutableEntry? _first;
  Entry? get firstOrNull => _first;
  Entry get first => firstOrNull!;

  /// An unmodifiable view of the unmodifiable list entries, keyed by value.
  UnmodifiableMapView<Point, Entry> get linkedVertexMap =>
      UnmodifiableMapView(_entries);

  ConvexHull(Iterable<Point> points, {this.onHullEvent}) {
    if (points.isEmpty) {
      _entries = {};
    } else {
      points = convexHull(points, x: (p) => p.x, y: (p) => p.y);
      _first = CircularLinkedListEntry.fromValues(points);
      _entries =
          Map.fromEntries(_first!.cycle.map((e) => MapEntry(e.value, e)));
    }
    onHullEvent?.call(HullInitialized(firstOrNull));
  }

  Iterable<_Edge> get _edges => _first?.cycle.map(_Edge.from) ?? const [];

  Iterable<Point> get vertices => linkedVertices.map((e) => e.value);

  /// The vertices of the convex hull in counter-clockwise order
  Iterable<Entry> get linkedVertices => _first?.cycle ?? const [];

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
    onHullEvent?.call(HullEvent.cleared);
  }

  void _split(_MutableEntry a, _MutableEntry b) {
    final split = CircularLinkedListEntry.split(a, b);
    if (split != null) {
      for (final e in split.cycle) {
        _entries.remove(e.value);
        if (e == _first) {
          _first = null;
        }
      }
    }
    _first ??= _compareEntries(a, b) < 0 ? a : b;
  }

  /// Add an entry, updating [_entries] and possibly [_first]
  _MutableEntry _addEntry(_MutableEntry entry) {
    final point = entry.value;
    _entries[point] = entry;
    // maybe replace first
    final first = _first;
    if (first == null || _compareEntries(entry, first) < 0) {
      _first = entry;
    }
    onHullEvent?.call(EntryAdded(entry));
    return entry;
  }

  _MutableEntry? _removeEntry(Entry entry) {
    final removed = _entries.remove(entry.value);
    if (removed == null) {
      throw ArgumentError('entry must be in the hull');
    }
    if (removed != entry) {
      throw ArgumentError(
          'entry.point found in the hull but belongs to a different entry');
    }
    final previous = removed.isIsolated ? null : removed.previous;
    if (removed == _first) {
      if (removed.isIsolated) {
        _first = null;
      } else {
        _first = _compareEntries(removed.previous, removed.next) < 0
            ? removed.previous
            : removed.next;
      }
    }
    removed.unlink();
    onHullEvent?.call(EntryRemoved(removed.value, previous));
    return previous;
  }

  void removeEntry(Entry entry) {
    _removeEntry(entry);
  }

  _MutableEntry? _addNear(Point point, _Edge nearby) {
    var startEdge = nearby.next;
    _MutableEntry? newPrevious;
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
    _MutableEntry? newNext;
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
  Entry? add(Point point) {
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
    removeEntry(entry);
    return true;
  }

  /// Move a point from [original] to [moved].
  ///
  /// Returns `true` if [moved] is a vertex of the new hull.
  Entry? move(Point original, Point moved) {
    final entry = _entries[original];
    if (entry == null) {
      throw ArgumentError('original must be in the hull');
    }
    return moveEntry(entry, moved);
  }

  Entry? moveEntry(Entry entry, Point moved) {
    if (entry.isIsolated) {
      removeEntry(entry);
      return _addEntry(CircularLinkedListEntry.isolated(moved));
    }
    final previous = _removeEntry(entry)!;
    return _addNear(moved, _Edge.from(previous));
  }
}
