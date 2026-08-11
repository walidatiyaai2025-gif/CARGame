import 'dart:math' as math;

const double _epsilon3d = 1e-9;

class Vec3 {
  const Vec3(this.x, this.y, this.z);

  static const Vec3 zero = Vec3(0, 0, 0);
  static const Vec3 up = Vec3(0, 1, 0);

  final double x;
  final double y;
  final double z;

  double get lengthSquared => (x * x) + (y * y) + (z * z);

  double get length => math.sqrt(lengthSquared);

  Vec3 normalized() {
    final magnitude = length;
    if (magnitude <= _epsilon3d) {
      throw ArgumentError.value(this, 'vector', 'Cannot normalize zero vector');
    }
    return this / magnitude;
  }

  double dot(Vec3 other) => (x * other.x) + (y * other.y) + (z * other.z);

  Vec3 cross(Vec3 other) => Vec3(
    (y * other.z) - (z * other.y),
    (z * other.x) - (x * other.z),
    (x * other.y) - (y * other.x),
  );

  double distanceTo(Vec3 other) => (this - other).length;

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);

  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);

  Vec3 operator *(double scalar) => Vec3(x * scalar, y * scalar, z * scalar);

  Vec3 operator /(double scalar) {
    if (scalar.abs() <= _epsilon3d) {
      throw ArgumentError.value(scalar, 'scalar', 'Cannot divide by zero');
    }
    return Vec3(x / scalar, y / scalar, z / scalar);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vec3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

class ScreenPoint3 {
  const ScreenPoint3(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenPoint3 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class Ray3 {
  Ray3({required this.origin, required Vec3 direction})
    : direction = direction.normalized();

  final Vec3 origin;
  final Vec3 direction;

  Vec3 at(double distance) => origin + (direction * distance);
}

class Plane3 {
  Plane3._(this.normal, this.offset);

  factory Plane3.fromPointNormal(Vec3 point, Vec3 normal) {
    final unitNormal = normal.normalized();
    return Plane3._(unitNormal, -unitNormal.dot(point));
  }

  final Vec3 normal;
  final double offset;

  double signedDistanceTo(Vec3 point) => normal.dot(point) + offset;

  Vec3? intersectRay(Ray3 ray) {
    final denominator = normal.dot(ray.direction);
    if (denominator.abs() <= _epsilon3d) {
      return null;
    }

    final distance = -signedDistanceTo(ray.origin) / denominator;
    if (distance < 0) {
      return null;
    }
    return ray.at(distance);
  }
}

class Aabb3 {
  const Aabb3({required this.min, required this.max});

  final Vec3 min;
  final Vec3 max;

  bool contains(Vec3 point) =>
      point.x >= min.x &&
      point.x <= max.x &&
      point.y >= min.y &&
      point.y <= max.y &&
      point.z >= min.z &&
      point.z <= max.z;
}
