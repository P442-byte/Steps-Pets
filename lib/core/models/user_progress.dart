import 'package:hive/hive.dart';

part 'user_progress.g.dart';

@HiveType(typeId: 2)
class UserProgress extends HiveObject {
  @HiveField(0)
  int totalStepsAllTime;

  @HiveField(1)
  int stepsToday;

  @HiveField(2)
  DateTime lastStepUpdate;

  @HiveField(3)
  int currentStreak;

  @HiveField(4)
  int longestStreak;

  @HiveField(5)
  DateTime lastActiveDate;

  @HiveField(6)
  int totalPetsHatched;

  @HiveField(7)
  int totalEggsReceived;

  @HiveField(8)
  List<String> unlockedMilestones;

  @HiveField(9)
  int nextMilestoneIndex;

  @HiveField(10)
  bool hasCompletedOnboarding;
  
  @HiveField(11)
  int dailyStepGoal;
  
  @HiveField(12)
  bool goalMetToday;
  
  @HiveField(13)
  int totalGoalDaysCompleted;

  UserProgress({
    this.totalStepsAllTime = 0,
    this.stepsToday = 0,
    DateTime? lastStepUpdate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastActiveDate,
    this.totalPetsHatched = 0,
    this.totalEggsReceived = 0,
    List<String>? unlockedMilestones,
    this.nextMilestoneIndex = 0,
    this.hasCompletedOnboarding = false,
    this.dailyStepGoal = 5000,
    this.goalMetToday = false,
    this.totalGoalDaysCompleted = 0,
  })  : lastStepUpdate = lastStepUpdate ?? DateTime.now(),
        lastActiveDate = lastActiveDate ?? DateTime.now(),
        unlockedMilestones = unlockedMilestones ?? [];

  /// Check if today is a new day and reset daily stats
  void checkAndResetDaily() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = DateTime(
      lastActiveDate.year,
      lastActiveDate.month,
      lastActiveDate.day,
    );

    if (today.isAfter(lastActive)) {
      // It's a new day
      final daysDifference = today.difference(lastActive).inDays;

      if (daysDifference == 1 && goalMetToday) {
        // Consecutive day with goal met - increment streak
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else if (daysDifference > 1 || !goalMetToday) {
        // Missed days or didn't meet goal - reset streak
        currentStreak = goalMetToday ? 1 : 0;
      }

      stepsToday = 0;
      goalMetToday = false;
      lastActiveDate = now;
      save();
    }
  }

  /// Add steps to progress
  void addSteps(int steps) {
    checkAndResetDaily();
    totalStepsAllTime += steps;
    stepsToday += steps;
    lastStepUpdate = DateTime.now();
    
    // Check if goal was just met
    if (!goalMetToday && stepsToday >= dailyStepGoal) {
      goalMetToday = true;
      totalGoalDaysCompleted++;
      // Start streak if this is first day
      if (currentStreak == 0) {
        currentStreak = 1;
      }
    }
    
    save();
  }

  /// Record a hatched pet
  void recordHatch() {
    totalPetsHatched++;
    save();
  }

  /// Record receiving an egg
  void recordEggReceived() {
    totalEggsReceived++;
    save();
  }

  /// Mark a milestone as unlocked
  void unlockMilestone(String milestoneId) {
    if (!unlockedMilestones.contains(milestoneId)) {
      unlockedMilestones.add(milestoneId);
      nextMilestoneIndex++;
      save();
    }
  }

  /// Check if a milestone is unlocked
  bool isMilestoneUnlocked(String milestoneId) {
    return unlockedMilestones.contains(milestoneId);
  }

  /// Complete onboarding
  void completeOnboarding() {
    hasCompletedOnboarding = true;
    save();
  }
  
  /// Update daily step goal
  void setDailyGoal(int goal) {
    dailyStepGoal = goal.clamp(1000, 50000);
    save();
  }

  /// Daily step goal (configurable)
  int get dailyGoal => dailyStepGoal;

  /// Progress towards daily goal (0.0 to 1.0)
  double get dailyProgress => (stepsToday / dailyGoal).clamp(0.0, 1.0);
  
  /// Steps remaining to meet goal
  int get stepsRemaining => (dailyGoal - stepsToday).clamp(0, dailyGoal);

  /// Format steps with commas
  String formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  String toString() =>
      'UserProgress(total: $totalStepsAllTime, today: $stepsToday, streak: $currentStreak)';
}

