import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  PetRarity? _filterRarity;
  PetType? _filterType;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        var pets = game.pets.toList();

        // Apply filters
        if (_filterRarity != null) {
          pets = pets.where((p) => p.rarity == _filterRarity).toList();
        }
        if (_filterType != null) {
          pets = pets.where((p) => p.type == _filterType).toList();
        }

        // Sort: favorites first, then by level
        pets.sort((a, b) {
          if (a.isFavorite != b.isFavorite) {
            return a.isFavorite ? -1 : 1;
          }
          return b.level.compareTo(a.level);
        });

        if (game.pets.isEmpty) {
          return _EmptyState();
        }

        return Column(
          children: [
            // Filter bar
            _FilterBar(
              selectedRarity: _filterRarity,
              selectedType: _filterType,
              onRarityChanged: (r) => setState(() => _filterRarity = r),
              onTypeChanged: (t) => setState(() => _filterType = t),
            ),

            // Pet count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${pets.length} pet${pets.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                  if (_filterRarity != null || _filterType != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _filterRarity = null;
                        _filterType = null;
                      }),
                      child: Text(
                        'Clear filters',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryTeal,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Pet grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  return PetCard(
                    pet: pet,
                    onTap: () => _showPetDetails(context, game, pet),
                  ).animate(delay: (index * 50).ms).fadeIn().scale(
                        begin: const Offset(0.95, 0.95),
                      );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPetDetails(BuildContext context, GameProvider game, Pet pet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PetDetailsSheet(pet: pet, game: game),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final PetRarity? selectedRarity;
  final PetType? selectedType;
  final ValueChanged<PetRarity?> onRarityChanged;
  final ValueChanged<PetType?> onTypeChanged;

  const _FilterBar({
    this.selectedRarity,
    this.selectedType,
    required this.onRarityChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: selectedRarity == null && selectedType == null,
              onTap: () {
                onRarityChanged(null);
                onTypeChanged(null);
              },
            ),
            const SizedBox(width: 8),
            ...PetType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: type.name,
                    color: Color(Pet.getTypeColor(type)),
                    isSelected: selectedType == type,
                    onTap: () => onTypeChanged(
                      selectedType == type ? null : type,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.secondaryTeal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppTheme.backgroundLight,
          ),
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _PetDetailsSheet extends StatelessWidget {
  final Pet pet;
  final GameProvider game;

  const _PetDetailsSheet({required this.pet, required this.game});

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

            // Pet avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: typeColor, width: 3),
              ),
              child: Icon(
                _getTypeIcon(pet.type),
                size: 40,
                color: typeColor,
              ),
            ),
            const SizedBox(height: 12),

            // Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pet.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                  onPressed: () => _showRenameDialog(context),
                  tooltip: 'Rename pet',
                ),
                IconButton(
                  icon: Icon(
                    pet.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: pet.isFavorite ? AppTheme.accentGold : AppTheme.textMuted,
                    size: 22,
                  ),
                  onPressed: () => game.togglePetFavorite(pet),
                ),
              ],
            ),

            // Species & badges
            Text(pet.species, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(pet.rarity.name, rarityColor),
                const SizedBox(width: 8),
                _Badge(pet.type.name, typeColor),
              ],
            ),
            const SizedBox(height: 16),

            // Stats
            _StatRow('Level', '${pet.level}'),
            _StatRow('Experience', '${pet.experience}/${pet.experienceToNextLevel}'),
            _StatRow('Steps Together', '${pet.totalStepsWalked}'),
            const SizedBox(height: 16),

            // Level progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level Progress', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pet.levelProgress,
                    backgroundColor: AppTheme.backgroundLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accentGold),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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

  IconData _getTypeIcon(PetType type) {
    switch (type) {
      case PetType.fire:
        return Icons.local_fire_department_rounded;
      case PetType.water:
        return Icons.water_drop_rounded;
      case PetType.earth:
        return Icons.landscape_rounded;
      case PetType.air:
        return Icons.air_rounded;
      case PetType.spirit:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_rounded, size: 80, color: AppTheme.textMuted.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text('No Pets Yet', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Text('Hatch eggs to collect pets!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

