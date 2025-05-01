class CountdownData {
  final String id;
  final String name;
  DateTime targetDate;
  bool isPaused;
  DateTime? pausedAt;
  Duration? remainingDuration;
  DateTime lastUpdated;

  CountdownData({
    required this.name,
    required this.targetDate,
    this.isPaused = false,
    this.pausedAt,
    this.remainingDuration,
    String? id,
    DateTime? lastUpdated,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        lastUpdated = lastUpdated ?? DateTime.now();

  void togglePause() {
    if (isPaused) {
      if (pausedAt != null) {
        final pauseDuration = DateTime.now().difference(pausedAt!);
        targetDate = targetDate.add(pauseDuration);
      }
      pausedAt = null;
    } else {
      pausedAt = DateTime.now();
      remainingDuration = targetDate.difference(pausedAt!);
    }
    isPaused = !isPaused;
    lastUpdated = DateTime.now();
  }

  Duration getRemainingDuration() {
    if (isPaused && remainingDuration != null) {
      return remainingDuration!;
    }
    return targetDate.difference(DateTime.now());
  }

  void updateAfterRestart() {
    if (!isPaused) {
      final now = DateTime.now();
      final elapsedSinceLastUpdate = now.difference(lastUpdated);
      lastUpdated = now;
      targetDate = targetDate.subtract(elapsedSinceLastUpdate);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetDate': targetDate.toIso8601String(),
      'isPaused': isPaused,
      'pausedAt': pausedAt?.toIso8601String(),
      'remainingDuration': remainingDuration?.inSeconds,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory CountdownData.fromJson(Map<String, dynamic> json) {
    return CountdownData(
      id: json['id'],
      name: json['name'],
      targetDate: DateTime.parse(json['targetDate']),
      isPaused: json['isPaused'],
      pausedAt:
          json['pausedAt'] != null ? DateTime.parse(json['pausedAt']) : null,
      remainingDuration: json['remainingDuration'] != null
          ? Duration(seconds: json['remainingDuration'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }
}
