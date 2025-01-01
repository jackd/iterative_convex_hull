import 'dart:collection';
import 'convex_hull.dart';
import 'point.dart';

class DelegatingConvexHull implements ConvexHull {
  final ConvexHull _base;
  DelegatingConvexHull.fromHull(ConvexHull base) : _base = base;

  @override
  Entry? add(Point point) => _base.add(point);

  @override
  void clear() => _base.clear();

  @override
  bool contains(Point point) => _base.contains(point);

  @override
  Entry get first => _base.first;

  @override
  Entry? get firstOrNull => _base.firstOrNull;

  @override
  bool get isEmpty => _base.isEmpty;

  @override
  bool get isNotEmpty => _base.isNotEmpty;

  @override
  bool isVertex(Point point) => _base.isVertex(point);

  @override
  UnmodifiableMapView<Point, Entry> get linkedVertexMap =>
      _base.linkedVertexMap;

  @override
  Iterable<Entry> get linkedVertices => _base.linkedVertices;

  @override
  Entry? move(Point original, Point moved) => _base.move(original, moved);

  @override
  Entry? moveEntry(Entry entry, Point moved) => _base.moveEntry(entry, moved);

  @override
  HullEventCallback? get onHullEvent => _base.onHullEvent;

  @override
  bool remove(Point point) => _base.remove(point);

  @override
  void removeEntry(Entry entry) => _base.removeEntry(entry);

  @override
  bool strictlyContains(Point point) => _base.strictlyContains(point);

  @override
  Iterable<Point> get vertices => _base.vertices;
}
