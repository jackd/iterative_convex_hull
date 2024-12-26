class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  @override
  int get hashCode => Object.hash(x, y);

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  double cross(Point other) => x * other.y - y * other.x;
  double dot(Point other) => x * other.x + y * other.y;

  double squaredLength() => x * x + y * y;

  Point operator -() => Point(-x, -y);
  Point operator -(Point other) => Point(x - other.x, y - other.y);
  Point operator +(Point other) => Point(x + other.x, y + other.y);
  Point operator *(double scalar) => Point(x * scalar, y * scalar);

  @override
  String toString() => 'Point($x, $y)';
}
