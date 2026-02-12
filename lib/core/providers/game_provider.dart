import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';

class GameProvider extends ChangeNotifier {
  // === Pet Limits ===
  static const int maxGardenPets = 20;
  static const int maxTotalPets = 100;
  static const int maxDebugPets = 50;

  final StorageService _storage;
  final StepTrackingService _stepService;
  final Uuid _uuid = const Uuid();

  UserProgress? _progress;
  List<Pet> _pets = [];
  List<Egg> _eggs = [];
  
  Timer? _stepUpdateTimer;
  int _lastKnownSteps = 0;
  bool _isInitialized = false;

  GameProvider({
    required StorageService storage,
    required StepTrackingService stepService,
  })  : _storage = storage,
        _stepService = stepService;

  // === Getters ===

  UserProgress get progress => _progress ?? UserProgress();
  List<Pet> get pets => List.unmodifiable(_pets);
  List<Egg> get eggs => List.unmodifiable(_eggs);
  List<Egg> get activeEggs => _eggs.where((e) => !e.isHatched).toList();
  List<Egg> get hatchableEggs => _eggs.where((e) => e.canHatch).toList();
  
  bool get isInitialized => _isInitialized;
  int get todaySteps => _stepService.todaySteps;
  StepTrackingStatus get stepTrackingStatus => _stepService.status;

  // === Initialization ===

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _storage.initialize();
    _progress = await _storage.getOrCreateProgress();
    _pets = _storage.getAllPets();
    _eggs = _storage.getAllEggs();

    // Initialize step tracking
    await _stepService.initialize();
    _lastKnownSteps = _stepService.todaySteps;

    // Start periodic step updates
    _startStepUpdateTimer();

    // Check for new user - give starter eggs
    if (!_progress!.hasCompletedOnboarding) {
      await _giveStarterEggs();
    }

    _isInitialized = true;
    notifyListeners();
  }

  void _startStepUpdateTimer() {
    _stepUpdateTimer?.cancel();
    _stepUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkForNewSteps(),
    );
  }

  Future<void> _checkForNewSteps() async {
    final currentSteps = await _stepService.fetchTodaySteps();
    final newSteps = currentSteps - _lastKnownSteps;

    if (newSteps > 0) {
      await _processNewSteps(newSteps);
      _lastKnownSteps = currentSteps;
    }
  }

  Future<void> _processNewSteps(int steps) async {
    // Update progress
    _progress?.addSteps(steps);

    // Add steps to all active eggs
    for (final egg in activeEggs) {
      egg.addSteps(steps);
    }

    // Add XP to all pets
    for (final pet in _pets) {
      pet.addSteps(steps);
    }

    // Check for milestone rewards
    await _checkMilestones();

    notifyListeners();
  }

  /// Manually trigger step sync
  Future<void> syncSteps() async {
    await _checkForNewSteps();
    notifyListeners();
  }

  // === Starter Eggs ===

  Future<void> _giveStarterEggs() async {
    // Give the first starter egg immediately
    final template = EggTemplates.starterEggs[0];
    await _createEggFromTemplate(template);
    _progress?.recordEggReceived();
    _progress?.completeOnboarding();
    notifyListeners();
  }

  // === Milestone System ===

  Future<void> _checkMilestones() async {
    if (_progress == null) return;

    final milestones = EggTemplates.starterMilestones;
    final nextIndex = _progress!.nextMilestoneIndex;

    if (nextIndex >= milestones.length) return;

    final nextMilestone = milestones[nextIndex];
    
    if (_progress!.totalStepsAllTime >= nextMilestone) {
      // Unlock next egg
      if (nextIndex < EggTemplates.starterEggs.length) {
        final template = EggTemplates.starterEggs[nextIndex];
        await _createEggFromTemplate(template);
        _progress!.unlockMilestone('starter_$nextIndex');
        _progress!.recordEggReceived();
      }
    }
  }

  // === Egg Management ===

  Future<Egg> _createEggFromTemplate(EggTemplate template) async {
    final egg = Egg(
      id: _uuid.v4(),
      name: template.name,
      rarityIndex: template.rarity.index,
      stepsRequired: template.stepsRequired,
      receivedAt: DateTime.now(),
      imageAsset: template.imageAsset,
      petSpeciesOnHatch: template.petSpecies,
    );

    await _storage.saveEgg(egg);
    _eggs.add(egg);
    notifyListeners();

    return egg;
  }

  Future<Pet?> hatchEgg(Egg egg) async {
    if (!egg.canHatch) return null;
    if (_pets.length >= maxDebugPets) return null;

    // Find the template to get pet type
    final template = EggTemplates.starterEggs.firstWhere(
      (t) => t.petSpecies == egg.petSpeciesOnHatch,
      orElse: () => EggTemplates.starterEggs[0],
    );

    // Create the pet
    final pet = Pet(
      id: _uuid.v4(),
      name: _generatePetName(template.petSpecies),
      species: template.petSpecies,
      rarityIndex: egg.rarityIndex,
      typeIndex: template.petType.index,
      hatchedAt: DateTime.now(),
      imageAsset: 'assets/images/pets/${template.petSpecies.toLowerCase()}.png',
    );

    // Save pet and mark egg as hatched
    await _storage.savePet(pet);
    egg.markHatched();
    
    _pets.add(pet);
    _progress?.recordHatch();

    notifyListeners();
    return pet;
  }

  String _generatePetName(String species) {
    // Simple name generation - can be expanded later
    final suffixes = ['y', 'ie', 'o', 'a', 'us', 'ix'];
    final suffix = suffixes[DateTime.now().millisecond % suffixes.length];
    final baseName = species.substring(0, (species.length * 0.6).round());
    return '$baseName$suffix';
  }

  // === Pet Management ===

  Future<void> togglePetFavorite(Pet pet) async {
    pet.isFavorite = !pet.isFavorite;
    await _storage.savePet(pet);
    notifyListeners();
  }
  
  /// Set the daily step goal
  void setDailyGoal(int goal) {
    _progress?.setDailyGoal(goal);
    notifyListeners();
  }
  
  /// Check if onboarding has been completed
  bool get hasCompletedOnboarding => _progress?.hasCompletedOnboarding ?? false;
  
  /// Mark onboarding as complete
  void completeOnboarding() {
    _progress?.completeOnboarding();
    notifyListeners();
  }

  Future<void> renamePet(Pet pet, String newName) async {
    // Create new pet with updated name (since name is final)
    final updatedPet = Pet(
      id: pet.id,
      name: newName,
      species: pet.species,
      rarityIndex: pet.rarityIndex,
      typeIndex: pet.typeIndex,
      level: pet.level,
      experience: pet.experience,
      hatchedAt: pet.hatchedAt,
      totalStepsWalked: pet.totalStepsWalked,
      imageAsset: pet.imageAsset,
      isFavorite: pet.isFavorite,
    );

    await _storage.savePet(updatedPet);
    final index = _pets.indexWhere((p) => p.id == pet.id);
    if (index != -1) {
      _pets[index] = updatedPet;
    }
    notifyListeners();
  }

  // === Debug/Testing ===

  /// Add mock steps (for testing without health API)
  Future<void> addMockSteps(int steps) async {
    if (_stepService is MockStepTrackingService) {
      (_stepService as MockStepTrackingService).addMockSteps(steps);
      // Update last known steps so the timer doesn't double-count
      _lastKnownSteps = _stepService.todaySteps;
    }
    await _processNewSteps(steps);
  }
  
  /// Add a test egg (for debugging)
  void addTestEgg() {
    final rarities = [PetRarity.common, PetRarity.uncommon, PetRarity.rare, PetRarity.epic, PetRarity.legendary];
    final types = PetType.values;
    final rarity = rarities[DateTime.now().millisecond % rarities.length];
    final type = types[DateTime.now().second % types.length];
    
    final speciesNames = {
      PetType.fire: 'Flameling',
      PetType.water: 'Bublet',
      PetType.earth: 'Rocklet',
      PetType.air: 'Zephyr',
      PetType.spirit: 'Phantling',
    };
    
    final egg = Egg(
      id: 'test_egg_${DateTime.now().millisecondsSinceEpoch}',
      name: '${rarity.name.substring(0, 1).toUpperCase()}${rarity.name.substring(1)} ${type.name} Egg',
      rarityIndex: rarity.index,
      stepsRequired: 10 + (rarity.index * 5), // Easy to hatch for testing
      stepsWalked: 0,
      receivedAt: DateTime.now(),
      imageAsset: '',
      petSpeciesOnHatch: speciesNames[type]!,
    );
    
    _eggs.add(egg);
    _storage.saveEgg(egg);
    _progress?.recordEggReceived();
    notifyListeners();
  }
  
  /// Add a test pet (for debugging). Returns false if at cap.
  bool addTestPet() {
    if (_pets.length >= maxDebugPets) return false;

    final types = PetType.values;
    final rarities = PetRarity.values;
    final type = types[DateTime.now().millisecond % types.length];
    final rarity = rarities[DateTime.now().second % rarities.length];
    
    final speciesNames = {
      PetType.fire: ['Flameling', 'Emberpup', 'Blazekit'],
      PetType.water: ['Bubbling', 'Splashlet', 'Dewdrop'],
      PetType.earth: ['Pebbling', 'Mudlet', 'Stonepup'],
      PetType.air: ['Breezeling', 'Gustlet', 'Cloudkit'],
      PetType.spirit: ['Shimmerling', 'Glowlet', 'Sparkpup'],
    };
    
    final species = speciesNames[type]![DateTime.now().millisecond % 3];
    
    final pet = Pet(
      id: 'test_pet_${DateTime.now().millisecondsSinceEpoch}',
      name: species,
      species: species,
      rarityIndex: rarity.index,
      typeIndex: type.index,
      level: 1,
      experience: 0,
      hatchedAt: DateTime.now(),
      totalStepsWalked: 0,
      imageAsset: '',
    );
    
    _pets.add(pet);
    _storage.savePet(pet);
    _progress?.recordHatch();
    notifyListeners();
    return true;
  }

  /// Delete a pet by ID (for debugging)
  Future<void> deletePet(String petId) async {
    _pets.removeWhere((p) => p.id == petId);
    await _storage.deletePet(petId);
    notifyListeners();
  }

  // === Cleanup ===

  // === Reset ===
  
  /// Reset all data and start fresh
  Future<void> resetAllData() async {
    await _storage.clearAllData();
    _pets.clear();
    _eggs.clear();
    _progress = null;
    _lastKnownSteps = 0;
    await initialize();
    notifyListeners();
  }

  // === Cleanup ===

  @override
  void dispose() {
    _stepUpdateTimer?.cancel();
    super.dispose();
  }
}

