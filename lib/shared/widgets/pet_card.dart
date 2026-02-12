import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import 'animated_monster.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final bool showLevel;
  final bool compact;

  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
    this.showLevel = true,
    this.compact = false,
  });

  MonsterType _getMonsterType(PetType type) {
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

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(Pet.getRarityColor(pet.rarity));

    if (compact) {
      return _buildCompactCard(context, rarityColor);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.rarityGradient(rarityColor),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: rarityColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Monster
              Stack(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: AnimatedMonster(
                      type: _getMonsterType(pet.type),
                      size: 70,
                      rarityLevel: pet.rarityIndex,
                    ),
                  ),
                  if (pet.isFavorite)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Pet name
              Text(
                pet.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Species
              Text(
                pet.species,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 6),

              // Rarity & Type badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(context, pet.rarity.name, rarityColor),
                  const SizedBox(width: 4),
                  _buildBadge(context, pet.type.name, Color(Pet.getTypeColor(pet.type))),
                ],
              ),

              if (showLevel) ...[
                const SizedBox(height: 8),
                // Level progress
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lv. ${pet.level}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                        ),
                        Text(
                          '${pet.experience}/${pet.experienceToNextLevel}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 9,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pet.levelProgress,
                        backgroundColor: AppTheme.backgroundLight,
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.accentGold),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, Color rarityColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: AppTheme.rarityGradient(rarityColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rarityColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 45,
              height: 45,
              child: AnimatedMonster(
                type: _getMonsterType(pet.type),
                size: 40,
                rarityLevel: pet.rarityIndex,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pet.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Lv.${pet.level}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 8,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
