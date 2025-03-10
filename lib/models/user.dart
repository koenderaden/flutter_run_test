class User {
  final String id;
  final String name;
  int steps;

  User({
    required this.id,
    required this.name,
    this.steps = 0,
  });
  }