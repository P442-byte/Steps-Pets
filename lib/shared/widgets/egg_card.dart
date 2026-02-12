import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import 'animated_monster.dart';

class EggCard extends StatelessWidget {
  final Egg egg;
  final VoidCallback? onTap;
  final VoidCallback? onHatch;

  const EggCard({
    super.key,
    required this.egg,
    this.onTap,
    this.onHatch,
  });

  MonsterType _getMonsterTypeFromSpecies(String species) {
    switch (species.toLowerCase()) {
      case 'flameling':
        return MonsterType.fire;
      case 'bublet':
        return MonsterType.water;
      case 'rocklet':
        return MonsterType.earth;
      case 'zephyr':
        return MonsterType.air;
      case 'phantling':
        return MonsterType.spirit;
      default:
        return MonsterType.spirit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(Pet.getRarityColor(egg.rarity));
    final monsterType = _getMonsterTypeFromSpecies(egg.petSpeciesOnHatch);

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
          boxShadow: egg.canHatch ? AppTheme.glowShadow(rarityColor) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Egg
              Flexible(
                child: SizedBox(
                  width: 70,
                  height: 85,
                  child: egg.canHatch
                      ? AnimatedMonster(
                          type: monsterType,
                          size: 65,
                          isEgg: true,
                          hatchProgress: egg.hatchProgress,
                          rarityLevel: egg.rarityIndex,
                        ).animate(
                          onPlay: (controller) => controller.repeat(),
                        ).shake(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(seconds: 2),
                          hz: 4,
                          rotation: 0.05,
                        )
                      : AnimatedMonster(
                          type: monsterType,
                          size: 65,
                          isEgg: true,
                          hatchProgress: egg.hatchProgress,
                          rarityLevel: egg.rarityIndex,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Egg name
              Text(
                egg.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Rarity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  egg.rarity.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: rarityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Progress bar
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: egg.hatchProgress,
                      backgroundColor: AppTheme.backgroundLight,
                      valueColor: AlwaysStoppedAnimation(rarityColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    egg.canHatch
                        ? 'Ready!'
                        : '${egg.stepsRemaining} steps',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: egg.canHatch
                              ? AppTheme.accentGold
                              : AppTheme.textMuted,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
              
              // Hatch button
              if (egg.canHatch && onHatch != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: onHatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rarityColor,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('HATCH!', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
