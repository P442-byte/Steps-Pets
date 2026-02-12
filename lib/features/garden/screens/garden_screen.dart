import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_monster.dart';
import '../../../shared/widgets/pet_garden.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  List<GardenPet> _gardenPets = [];
  bool _initialized = false;
  final StorageService _storage = StorageService();
  Map<String, Map<String, double>> _savedPositions = {};

  @override
  void initState() {
    super.initState();
    _loadSavedPositions();
  }
  
  Future<void> _loadSavedPositions() async {
    await _storage.initialize();
    setState(() {
      _savedPositions = _storage.getGardenPositions();
    });
  }
  
  void _savePositions() {
    final positions = <String, Map<String, double>>{};
    for (final pet in _gardenPets) {
      positions[pet.id] = {
        'x': pet.position.dx,
        'y': pet.position.dy,
      };
    }
    _storage.saveGardenPositions(positions);
  }

  MonsterType _petTypeToMonsterType(PetType type) {
    switch (type) {
      case PetType.fire:
        return MonsterType.fire;
      case PetType.water:
        return MonsterType.water;
      case PetType.earth:
        return MonsterType.earth;
      case PetType.air:
        return MonsterType.air;
      case PetType.spirit:
        return MonsterType.spirit;
    }
  }

  void _initializeGardenPets(List<Pet> pets) {
    if (_initialized && _gardenPets.length == pets.length) return;
    
    final random = Random();
    _gardenPets = pets.map((pet) {
      // Check if pet already exists in garden
      final existing = _gardenPets.where((gp) => gp.id == pet.id).firstOrNull;
      if (existing != null) return existing;
      
      // Check for saved position
      final savedPos = _savedPositions[pet.id];
      final position = savedPos != null
          ? Offset(savedPos['x']!, savedPos['y']!)
          : Offset(
              50 + random.nextDouble() * 200,
              50 + random.nextDouble() * 200,
            );
      
      return GardenPet(
        id: pet.id,
        name: pet.name,
        type: _petTypeToMonsterType(pet.type),
        level: pet.level,
        position: position,
        rarityLevel: pet.rarityIndex,
      );
    }).toList();
    
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        final pets = game.pets;
        
        if (pets.isEmpty) {
          return _buildEmptyGarden(context);
        }

        // Limit garden display to max garden pets
        final gardenPets = pets.length > GameProvider.maxGardenPets
            ? pets.sublist(pets.length - GameProvider.maxGardenPets)
            : pets;

        _initializeGardenPets(gardenPets);

        return Stack(
          children: [
            // Garden area
            PetGarden(
              pets: _gardenPets,
              onPetTap: (gardenPet) => _showPetInfo(context, game, gardenPet),
              onPositionsChanged: _savePositions,
            ),
            
            // Top info bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.park_rounded,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Garden',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pets_rounded,
                            color: AppTheme.accentGold,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pets.length > GameProvider.maxGardenPets
                                ? '${gardenPets.length}/${pets.length}'
                                : '${pets.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom hint
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap a pet to see details',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyGarden(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a2a1a),
            Color(0xFF2d4a2d),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.park_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Garden is Empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hatch some eggs to populate\nyour garden with pets!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPetInfo(BuildContext context, GameProvider game, GardenPet gardenPet) {
    // Find the actual pet data
    final pet = game.pets.where((p) => p.id == gardenPet.id).firstOrNull;
    if (pet == null) return;
    
    // Play pet tap sound
    context.read<SoundService>().play(SoundType.petTap);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PetInfoSheet(
        pet: pet, 
        gardenPet: gardenPet,
        game: game,
        onGiveAttention: () {
          // Trigger happy animation
          setState(() {
            gardenPet.behavior = PetBehavior.playing;
            gardenPet.behaviorTimer = 100; // Play for ~5 seconds
          });
          Navigator.pop(context);
          
          // Show a little feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('💕'),
                  const SizedBox(width: 8),
                  Text('${pet.name} is happy!'),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PetInfoSheet extends StatelessWidget {
  final Pet pet;
  final GardenPet gardenPet;
  final VoidCallback? onGiveAttention;
  final GameProvider game;

  const _PetInfoSheet({
    required this.pet, 
    required this.gardenPet,
    required this.game,
    this.onGiveAttention,
  });

  String _getBehaviorText(PetBehavior behavior) {
    switch (behavior) {
      case PetBehavior.idle:
        return 'Relaxing';
      case PetBehavior.walking:
        return 'Exploring';
      case PetBehavior.sleeping:
        return 'Sleeping 💤';
      case PetBehavior.playing:
        return 'Playing ✨';
      case PetBehavior.beingDragged:
        return 'Being carried 😊';
    }
  }
  
  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: pet.name);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Rename Pet'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != pet.name) {
                game.renamePet(pet, newName);
                Navigator.pop(dialogContext);
                Navigator.pop(context); // Close the details sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Renamed to $newName!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(Pet.getRarityColor(pet.rarity));
    final typeColor = Color(Pet.getTypeColor(pet.type));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Pet display
            Row(
              children: [
                // Animated monster
                SizedBox(
                  width: 70,
                  height: 70,
                  child: AnimatedMonster(
                    type: gardenPet.type,
                    size: 60,
                    rarityLevel: gardenPet.rarityLevel,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            color: AppTheme.textMuted,
                            onPressed: () => _showRenameDialog(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      Text(
                        pet.species,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(pet.rarity.name, rarityColor),
                          const SizedBox(width: 6),
                          _Badge(pet.type.name, typeColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current activity
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mood_rounded,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Activity',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _getBehaviorText(gardenPet.behavior),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.trending_up_rounded,
                    label: 'Level',
                    value: '${pet.level}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.directions_walk_rounded,
                    label: 'Steps',
                    value: '${pet.totalStepsWalked}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Level progress
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${pet.level}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${pet.experience}/${pet.experienceToNextLevel} XP',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pet.levelProgress,
                      backgroundColor: AppTheme.surfaceCard,
                      valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Give Attention button
            if (onGiveAttention != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onGiveAttention,
                  icon: const Text('💕', style: TextStyle(fontSize: 16)),
                  label: const Text('Give Attention'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.secondaryTeal, size: 18),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

