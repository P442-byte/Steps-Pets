import 'package:hive/hive.dart';
import 'pet.dart';

part 'egg.g.dart';

@HiveType(typeId: 1)
class Egg extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int rarityIndex;

  @HiveField(3)
  final int stepsRequired;

  @HiveField(4)
  int stepsWalked;

  @HiveField(5)
  final DateTime receivedAt;

  @HiveField(6)
  final String imageAsset;

  @HiveField(7)
  final String petSpeciesOnHatch;

  @HiveField(8)
  bool isHatched;

  Egg({
    required this.id,
    required this.name,
    required this.rarityIndex,
    required this.stepsRequired,
    this.stepsWalked = 0,
    required this.receivedAt,
    required this.imageAsset,
    required this.petSpeciesOnHatch,
    this.isHatched = false,
  });

  PetRarity get rarity => PetRarity.values[rarityIndex];

  /// Progress towards hatching (0.0 to 1.0)
  double get hatchProgress => (stepsWalked / stepsRequired).clamp(0.0, 1.0);

  /// Steps remaining until hatch
  int get stepsRemaining => (stepsRequired - stepsWalked).clamp(0, stepsRequired);

  /// Whether the egg is ready to hatch
  bool get canHatch => stepsWalked >= stepsRequired && !isHatched;

  /// Add steps to this egg
  void addSteps(int steps) {
    if (!isHatched) {
      stepsWalked += steps;
      save();
    }
  }

  /// Mark as hatched
  void markHatched() {
    isHatched = true;
    save();
  }

  @override
  String toString() => 'Egg($name, ${(hatchProgress * 100).toStringAsFixed(1)}%)';
}

/// Predefined egg types for the game
class EggTemplates {
  static const List<EggTemplate> starterEggs = [
    EggTemplate(
      name: 'Ember Egg',
      rarity: PetRarity.common,
      stepsRequired: 10,
      imageAsset: 'assets/images/eggs/ember_egg.png',
      petSpecies: 'Flameling',
      petType: PetType.fire,
    ),
    EggTemplate(
      name: 'Dewdrop Egg',
      rarity: PetRarity.common,
      stepsRequired: 20,
      imageAsset: 'assets/images/eggs/dewdrop_egg.png',
      petSpecies: 'Bublet',
      petType: PetType.water,
    ),
    EggTemplate(
      name: 'Pebble Egg',
      rarity: PetRarity.common,
      stepsRequired: 40,
      imageAsset: 'assets/images/eggs/pebble_egg.png',
      petSpecies: 'Rocklet',
      petType: PetType.earth,
    ),
    EggTemplate(
      name: 'Breeze Egg',
      rarity: PetRarity.uncommon,
      stepsRequired: 70,
      imageAsset: 'assets/images/eggs/breeze_egg.png',
      petSpecies: 'Zephyr',
      petType: PetType.air,
    ),
    EggTemplate(
      name: 'Mystic Egg',
      rarity: PetRarity.rare,
      stepsRequired: 100,
      imageAsset: 'assets/images/eggs/mystic_egg.png',
      petSpecies: 'Phantling',
      petType: PetType.spirit,
    ),
  ];

  /// Get cumulative step milestones for starter eggs
  static List<int> get starterMilestones => [10, 30, 70, 140, 240];
}

/// Template for creating eggs
class EggTemplate {
  final String name;
  final PetRarity rarity;
  final int stepsRequired;
  final String imageAsset;
  final String petSpecies;
  final PetType petType;

  const EggTemplate({
    required this.name,
    required this.rarity,
    required this.stepsRequired,
    required this.imageAsset,
    required this.petSpecies,
    required this.petType,
  });
}

