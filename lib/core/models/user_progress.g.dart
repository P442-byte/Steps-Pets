// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 2;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      totalStepsAllTime: fields[0] as int,
      stepsToday: fields[1] as int,
      lastStepUpdate: fields[2] as DateTime?,
      currentStreak: fields[3] as int,
      longestStreak: fields[4] as int,
      lastActiveDate: fields[5] as DateTime?,
      totalPetsHatched: fields[6] as int,
      totalEggsReceived: fields[7] as int,
      unlockedMilestones: (fields[8] as List?)?.cast<String>(),
      nextMilestoneIndex: fields[9] as int,
      hasCompletedOnboarding: fields[10] as bool,
      dailyStepGoal: fields[11] as int,
      goalMetToday: fields[12] as bool,
      totalGoalDaysCompleted: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.totalStepsAllTime)
      ..writeByte(1)
      ..write(obj.stepsToday)
      ..writeByte(2)
      ..write(obj.lastStepUpdate)
      ..writeByte(3)
      ..write(obj.currentStreak)
      ..writeByte(4)
      ..write(obj.longestStreak)
      ..writeByte(5)
      ..write(obj.lastActiveDate)
      ..writeByte(6)
      ..write(obj.totalPetsHatched)
      ..writeByte(7)
      ..write(obj.totalEggsReceived)
      ..writeByte(8)
      ..write(obj.unlockedMilestones)
      ..writeByte(9)
      ..write(obj.nextMilestoneIndex)
      ..writeByte(10)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(11)
      ..write(obj.dailyStepGoal)
      ..writeByte(12)
      ..write(obj.goalMetToday)
      ..writeByte(13)
      ..write(obj.totalGoalDaysCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
