import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class StorageService {
  static const String _petsBoxName = 'pets';
  static const String _eggsBoxName = 'eggs';
  static const String _progressBoxName = 'progress';
  static const String _settingsBoxName = 'settings';
  static const String _progressKey = 'user_progress';
  static const String _gardenPositionsKey = 'garden_positions';
  static const String _favoritePetKey = 'favorite_pet';

  late Box<Pet> _petsBox;
  late Box<Egg> _eggsBox;
  late Box<UserProgress> _progressBox;
  late Box<dynamic> _settingsBox;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PetAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(EggAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserProgressAdapter());
    }

    // Open boxes
    _petsBox = await Hive.openBox<Pet>(_petsBoxName);
    _eggsBox = await Hive.openBox<Egg>(_eggsBoxName);
    _progressBox = await Hive.openBox<UserProgress>(_progressBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

    _isInitialized = true;
  }

  // === User Progress ===

  UserProgress getUserProgress() {
    return _progressBox.get(_progressKey) ?? UserProgress();
  }

  Future<void> saveUserProgress(UserProgress progress) async {
    await _progressBox.put(_progressKey, progress);
  }

  Future<UserProgress> getOrCreateProgress() async {
    var progress = _progressBox.get(_progressKey);
    if (progress == null) {
      progress = UserProgress();
      await _progressBox.put(_progressKey, progress);
    }
    return progress;
  }

  // === Pets ===

  List<Pet> getAllPets() {
    return _petsBox.values.toList();
  }

  Pet? getPet(String id) {
    return _petsBox.get(id);
  }

  Future<void> savePet(Pet pet) async {
    await _petsBox.put(pet.id, pet);
  }

  Future<void> deletePet(String id) async {
    await _petsBox.delete(id);
  }

  int get petCount => _petsBox.length;

  // === Eggs ===

  List<Egg> getAllEggs() {
    return _eggsBox.values.toList();
  }

  List<Egg> getActiveEggs() {
    return _eggsBox.values.where((egg) => !egg.isHatched).toList();
  }

  Egg? getEgg(String id) {
    return _eggsBox.get(id);
  }

  Future<void> saveEgg(Egg egg) async {
    await _eggsBox.put(egg.id, egg);
  }

  Future<void> deleteEgg(String id) async {
    await _eggsBox.delete(id);
  }

  int get eggCount => _eggsBox.length;

  int get activeEggCount => _eggsBox.values.where((e) => !e.isHatched).length;

  // === Utility ===

  Future<void> clearAllData() async {
    await _petsBox.clear();
    await _eggsBox.clear();
    await _progressBox.clear();
    await _settingsBox.clear();
  }

  Future<void> close() async {
    await _petsBox.close();
    await _eggsBox.close();
    await _progressBox.close();
    await _settingsBox.close();
  }
  
  // === Garden Positions ===
  
  /// Save pet positions in garden as Map<petId, {x, y}>
  Future<void> saveGardenPositions(Map<String, Map<String, double>> positions) async {
    await _settingsBox.put(_gardenPositionsKey, positions);
  }
  
  /// Get saved garden positions
  Map<String, Map<String, double>> getGardenPositions() {
    final data = _settingsBox.get(_gardenPositionsKey);
    if (data == null) return {};
    
    // Convert to proper type
    final Map<String, Map<String, double>> result = {};
    (data as Map).forEach((key, value) {
      result[key as String] = {
        'x': (value['x'] as num).toDouble(),
        'y': (value['y'] as num).toDouble(),
      };
    });
    return result;
  }
  
  // === Favorite Pet ===
  
  Future<void> saveFavoritePet(String? petId) async {
    if (petId == null) {
      await _settingsBox.delete(_favoritePetKey);
    } else {
      await _settingsBox.put(_favoritePetKey, petId);
    }
  }
  
  String? getFavoritePet() {
    return _settingsBox.get(_favoritePetKey) as String?;
  }
}

