enum Direction {
  long,
  short;

  String toJson() => name.toUpperCase();

  static Direction fromJson(String value) {
    switch (value.toUpperCase()) {
      case 'SHORT':
        return Direction.short;
      default:
        return Direction.long;
    }
  }

  @override
  String toString() => name.toUpperCase();
}
