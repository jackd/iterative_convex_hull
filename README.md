# iterative_convex_hull

Provides dart classes for computing convex hulls iteratively.

## Features

- `ConvexHull` class designed for iterative updates
  - initial construction is done in log-linear time using [convex_hull](https://pub.dev/packages/convex_hull)
  - `add` and `remove` are done in linear time/space.
  - `move` (a combined `remove` and `add`) is done in constant time/space for sufficiently small movements.
    - worst-case is linear
- `BoundedConvexHull` which extends `ConvexHull` with `PointRange` and `onRangeChange` callbacks to efficiently respond to changes in a bounding box around all vertices.
  - `onRangeChange` only triggers when the bounding box changes due to an `add`, `remove` or `move`
  - updates are computed in constant time

## Getting started

To run examples:

Add the following to your `pubspec.yaml`:

```.yaml
dependencies:
    iterative_convex_hull:
        git: https://github.com/jackd/iterative_convex_hull.git
```

## Usage

See [test](./test/) and [example](./example/) directories for more examples.

```dart
import 'package:iterative_convex_hull/iterative_convex_hull.dart';

void main() {
  // create a hull from any iterable of points
  // note this uses an efficient non-iterative implementation provided by
  // [convex_hull](https://pub.dev/packages/convex_hull).
  final hull = ConvexHull(
      [Point(0, 0), Point(0, 1), Point(1, 0), Point(1, 1), Point(0.5, 0.5)]);
  // check vertices
  assert(hull.isVertex(Point(0, 0)));
  // interior points are not considered vertices
  assert(hull.vertices.length == 4);
  assert(hull.isVertex(Point(0.5, 0.5)) == false);
  // interior points are 'contained'
  assert(hull.contains(Point(0.5, 0.5)));
  assert(hull.contains(Point(0.4, 0.4)));
  // iterate over vertices in counter-clockwise order
  for (var point in hull.vertices) {
    print(point);
  }
  // attempting to add points on the inside is fine, returns false
  var added = hull.add(Point(0.3, 0.3));
  assert(!added);
  // adding new vertices returns true
  added = hull.add(Point(2, 0));
  assert(added);

  var removed = hull.remove(Point(2, 0));
  assert(removed);
  // removing a non-vertex will return false
  removed = hull.remove(Point(2, 0));
  assert(!removed);
  removed = hull.remove(Point(0, 0.5));
  assert(!removed);

  // access vertices in a CircularLinkedListEntry<Point>
  final bottomRightEntry = hull.linkedVertexMap[Point(1, 1)]!;
  assert(bottomRightEntry.value == Point(1, 1));
  assert(bottomRightEntry.previous.value == Point(0, 1));
  assert(bottomRightEntry.next.value == Point(1, 1));
}
```
