abstract interface class UnmodifiableCircularLinkedListEntryView<T> {
  T get value;

  /// Get the next entry in the cycle. Is `this` iff a trivial cycle.
  UnmodifiableCircularLinkedListEntryView<T> get next;

  /// Get the previous entry in the cycle. Is `this` iff a trivial cycle.
  UnmodifiableCircularLinkedListEntryView<T> get previous;

  /// Returns `true` iff `this` is a trivial cycle.
  bool get isIsolated;
}

class CircularLinkedListEntry<T>
    implements UnmodifiableCircularLinkedListEntryView<T> {
  CircularLinkedListEntry<T>? _next;
  CircularLinkedListEntry<T>? _previous;

  @override
  final T value;

  CircularLinkedListEntry._(this.value);

  CircularLinkedListEntry.isolated(this.value);

  /// Creates a circular linked list from an iterable.
  ///
  /// Returns the entry of the first element.
  factory CircularLinkedListEntry.fromValues(Iterable<T> values) {
    if (values.isEmpty) {
      throw ArgumentError('values must not be empty');
    }
    var iter = values.iterator;

    iter.moveNext();
    final first = CircularLinkedListEntry<T>.isolated(iter.current);
    var current = first;
    while (iter.moveNext()) {
      final next = CircularLinkedListEntry<T>.isolated(iter.current);
      current._next = next;
      next._previous = current;
      current = next;
    }
    // complete the loop
    if (first != current) {
      current._next = first;
      first._previous = current;
    }
    return first;
  }

  /// Creates a copy of this entry and all connected entries.
  ///
  /// Note the values are not copied.
  CircularLinkedListEntry<T> copy() {
    final first = CircularLinkedListEntry._(value);
    var current = first;
    for (final e in first.entries.skip(1)) {
      final next = CircularLinkedListEntry._(e.value);
      current._next = next;
      next._previous = current;
      current = next;
    }
    current._next = first;
    first._previous = current;
    return first;
  }

  /// Splits the cycle into two.
  /// b -> ... a ->
  /// a.next -> ... b.previous ->
  ///
  /// Returns [null] if [a.next] == [b] (i.e. the cycle is not split),
  /// otherwise [a.next] (i.e. a reference to the split off cycle).
  static CircularLinkedListEntry<T>? split<T>(
      CircularLinkedListEntry<T> a, CircularLinkedListEntry<T> b) {
    if (a == b || a.next == b) {
      return null;
    }
    final aNext = a.next;
    final bPrevious = b.previous;
    bPrevious._next = aNext;
    aNext._previous = bPrevious;

    a._next = b;
    b._previous = a;
    return aNext;
  }

  @override
  CircularLinkedListEntry<T> get next => _next ?? this;
  @override
  CircularLinkedListEntry<T> get previous => _previous ?? this;

  /// Remove this entry from a cycle.
  void unlink() {
    final n = _next;
    final p = _previous;
    if (n == null || p == null) {
      return;
    }
    if (n == p) {
      // loop of 2 points - unlink both
      n._next = null;
      n._previous = null;
    } else {
      n._previous = p;
      p._next = n;
    }
    _previous = null;
    _next = null;
  }

  /// Create a new [CircularLinkedListEntry] wrapping [value] and insert it
  /// after this entry.
  CircularLinkedListEntry<T> insertAfter(T value) {
    final entry = CircularLinkedListEntry.isolated(value);
    entry._next = next;
    entry._previous = this;
    next._previous = entry;
    _next = entry;
    return entry;
  }

  /// Create a new [CircularLinkedListEntry] wrapping [value] and insert it
  /// before this entry.
  CircularLinkedListEntry<T> insertBefore(T value) =>
      previous.insertAfter(value);

  /// Returns `true` if this entry is isolated / has a self-loop.
  @override
  bool get isIsolated => _next == null;

  /// Iterates over all reachable entries using [next], starting at this.
  Iterable<CircularLinkedListEntry<T>> get entries sync* {
    yield this;
    var current = this.next;
    while (current != this) {
      yield current;
      current = current.next;
    }
  }

  /// Same as [entries].toList().reversed, i.e. yields `this` last.
  Iterable<CircularLinkedListEntry<T>> get reversedEntries sync* {
    var current = previous;
    while (current != this) {
      yield current;
      current = current.previous;
    }
    yield this;
  }

  /// Get all entries from this to [other], including this but not [other].
  ///
  /// Will not do more than a full cycle if [other] is not found.
  Iterable<CircularLinkedListEntry<T>> entriesTo(
          CircularLinkedListEntry<T> other) =>
      entries.takeWhile((e) => e != other);
}
