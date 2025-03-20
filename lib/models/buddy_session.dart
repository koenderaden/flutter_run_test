import 'package:cloud_firestore/cloud_firestore.dart';

class BuddySession {
  final String sessionId;
  final String hostId;
  final String? buddyId;
  final int hostSteps;
  final int buddySteps;

  BuddySession({
    required this.sessionId,
    required this.hostId,
    this.buddyId,
    this.hostSteps = 0,
    this.buddySteps = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'hostId': hostId,
      'buddyId': buddyId,
      'hostSteps': hostSteps,
      'buddySteps': buddySteps,
    };
  }

  factory BuddySession.fromMap(Map<String, dynamic> map) {
    return BuddySession(
      sessionId: map['sessionId'],
      hostId: map['hostId'],
      buddyId: map['buddyId'],
      hostSteps: map['hostSteps'] ?? 0,
      buddySteps: map['buddySteps'] ?? 0,
    );
  }
}
