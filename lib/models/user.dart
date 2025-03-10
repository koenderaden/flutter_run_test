class User {
  final String id;
  final String name;
  int steps;
  bool isOnline;

  User({
    required this.id,
    required this.name,
    this.steps = 0,
    this.isOnline = true,
  });
} 