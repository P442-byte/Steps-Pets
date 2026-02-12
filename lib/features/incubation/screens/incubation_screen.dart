import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class IncubationScreen extends StatelessWidget {
  const IncubationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        final activeEggs = game.activeEggs;
        final hatchedEggs = game.eggs.where((e) => e.isHatched).toList();

        if (activeEggs.isEmpty && hatchedEggs.isEmpty) {
          return _EmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Milestone progress
              _MilestoneProgress(
                totalSteps: game.progress.totalStepsAllTime,
                nextMilestoneIndex: game.progress.nextMilestoneIndex,
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 24),

              // Active eggs section
              if (activeEggs.isNotEmpty) ...[
                Text(
                  'Incubating (${activeEggs.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: activeEggs.length,
                  itemBuilder: (context, index) {
                    final egg = activeEggs[index];
                    return EggCard(
                      egg: egg,
                      onHatch: egg.canHatch
                          ? () => _hatchEgg(context, game, egg)
                          : null,
                    ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.2);
                  },
                ),
              ],

              if (activeEggs.isEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.egg_outlined,
                        size: 64,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No eggs incubating',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep walking to earn more eggs!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Hatched eggs history
              if (hatchedEggs.isNotEmpty) ...[
                Text(
                  'Hatched (${hatchedEggs.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
                const SizedBox(height: 12),
                ...hatchedEggs.map((egg) => _HatchedEggTile(egg: egg)),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _hatchEgg(BuildContext context, GameProvider game, egg) async {
    final pet = await game.hatchEgg(egg);
    if (pet != null && context.mounted) {
      _showHatchAnimation(context, pet);
    }
  }

  void _showHatchAnimation(BuildContext context, pet) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _HatchingDialog(pet: pet),
    );
  }
}

class _MilestoneProgress extends StatelessWidget {
  final int totalSteps;
  final int nextMilestoneIndex;

  const _MilestoneProgress({
    required this.totalSteps,
    required this.nextMilestoneIndex,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = [10, 30, 70, 140, 240];
    final nextMilestone = nextMilestoneIndex < milestones.length
        ? milestones[nextMilestoneIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                color: AppTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Milestone Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (nextMilestone != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalSteps / $nextMilestone steps',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                Text(
                  'Next: Egg ${nextMilestoneIndex + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.accentGold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (totalSteps / nextMilestone).clamp(0.0, 1.0),
                backgroundColor: AppTheme.backgroundLight,
                valueColor: const AlwaysStoppedAnimation(AppTheme.accentGold),
                minHeight: 8,
              ),
            ),
          ] else ...[
            Text(
              'All starter milestones completed! 🎉',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentGold,
                  ),
            ),
          ],

          const SizedBox(height: 16),
          
          // Milestone indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(milestones.length, (index) {
              final isCompleted = index < nextMilestoneIndex;
              final isCurrent = index == nextMilestoneIndex;
              
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.accentGold
                          : isCurrent
                              ? AppTheme.accentGold.withOpacity(0.3)
                              : AppTheme.backgroundLight,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppTheme.accentGold, width: 2)
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.egg_outlined,
                      size: 16,
                      color: isCompleted
                          ? Colors.white
                          : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${milestones[index]}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isCompleted || isCurrent
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HatchedEggTile extends StatelessWidget {
  final Egg egg;

  const _HatchedEggTile({required this.egg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.egg_alt_rounded,
            color: AppTheme.textMuted,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              egg.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.egg_outlined,
              size: 80,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Eggs Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start walking to earn your first egg!\nYour first egg awaits at 10 steps.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HatchingDialog extends StatefulWidget {
  final Pet pet;

  const _HatchingDialog({required this.pet});

  @override
  State<_HatchingDialog> createState() => _HatchingDialogState();
}

class _HatchingDialogState extends State<_HatchingDialog> {
  bool _showPet = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showPet = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_showPet) ...[
              const Icon(
                Icons.egg_alt_rounded,
                size: 80,
                color: AppTheme.accentGold,
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shake(duration: 200.ms)
                  .then(delay: 300.ms)
                  .shake(duration: 200.ms),
              const SizedBox(height: 16),
              Text(
                'Hatching...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ] else ...[
              const Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: AppTheme.accentGold,
              ).animate().fadeIn().scale(),
              const SizedBox(height: 16),
              Text(
                '${widget.pet.name} hatched!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              PetCard(pet: widget.pet, showLevel: false)
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Welcome!'),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

