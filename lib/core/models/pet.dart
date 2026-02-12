import 'package:hive/hive.dart';

part 'pet.g.dart';

/// Rarity levels for pets
enum PetRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Pet types/elements
enum PetType {
  fire,
  water,
  earth,
  air,
  spirit,
}

@HiveType(typeId: 0)
class Pet extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String species;

  @HiveField(3)
  final int rarityIndex; // Store as int for Hive

  @HiveField(4)
  final int typeIndex; // Store as int for Hive

  @HiveField(5)
  int level;

  @HiveField(6)
  int experience;

  @HiveField(7)
  final DateTime hatchedAt;

  @HiveField(8)
  int totalStepsWalked;

  @HiveField(9)
  final String imageAsset;

  @HiveField(10)
  bool isFavorite;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.rarityIndex,
    required this.typeIndex,
    this.level = 1,
    this.experience = 0,
    required this.hatchedAt,
    this.totalStepsWalked = 0,
    required this.imageAsset,
    this.isFavorite = false,
  });

  PetRarity get rarity => PetRarity.values[rarityIndex];
  PetType get type => PetType.values[typeIndex];

  /// Experience needed to reach next level
  int get experienceToNextLevel => level * 100;

  /// Progress to next level (0.0 to 1.0)
  double get levelProgress => experience / experienceToNextLevel;

  /// Add experience and handle level ups
  void addExperience(int amount) {
    experience += amount;
    while (experience >= experienceToNextLevel && level < 100) {
      experience -= experienceToNextLevel;
      level++;
    }
    save();
  }

  /// Add steps walked with this pet
  void addSteps(int steps) {
    totalStepsWalked += steps;
    // 1 XP per 10 steps
    addExperience(steps ~/ 10);
  }

  /// Get color associated with rarity
  static int getRarityColor(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.common:
        return 0xFF9E9E9E; // Grey
      case PetRarity.uncommon:
        return 0xFF4CAF50; // Green
      case PetRarity.rare:
        return 0xFF2196F3; // Blue
      case PetRarity.epic:
        return 0xFF9C27B0; // Purple
      case PetRarity.legendary:
        return 0xFFFF9800; // Orange/Gold
    }
  }

  /// Get color associated with type
  static int getTypeColor(PetType type) {
    switch (type) {
      case PetType.fire:
        return 0xFFE53935; // Red
      case PetType.water:
        return 0xFF1E88E5; // Blue
      case PetType.earth:
        return 0xFF6D4C41; // Brown
      case PetType.air:
        return 0xFF90CAF9; // Light Blue
      case PetType.spirit:
        return 0xFFAB47BC; // Purple
    }
  }

  @override
  String toString() => 'Pet($name, Lv.$level ${rarity.name} ${type.name})';
}

