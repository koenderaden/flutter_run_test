class User {
  final String username;
  int steps;
  bool isOnline;

  User({
    required this.username,
    this.steps = 0,
    this.isOnline = true,
  });
} 