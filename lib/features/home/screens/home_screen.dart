import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        final progress = game.progress;
        final activeEggs = game.activeEggs;
        final hatchableEggs = game.hatchableEggs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Step Progress Ring
              StepProgressRing(
                progress: progress.dailyProgress,
                currentSteps: progress.stepsToday,
                goalSteps: progress.dailyGoal,
                size: 200,
              ).animate().fadeIn(duration: 600.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 24),

              // Daily Goal & Streak Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: progress.goalMetToday 
                      ? Border.all(color: AppTheme.primaryGreen, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    // Goal status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: progress.goalMetToday 
                                ? AppTheme.primaryGreen.withOpacity(0.2)
                                : AppTheme.backgroundLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            progress.goalMetToday 
                                ? Icons.check_circle_rounded
                                : Icons.flag_rounded,
                            color: progress.goalMetToday 
                                ? AppTheme.primaryGreen
                                : AppTheme.textMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                progress.goalMetToday 
                                    ? 'Daily Goal Complete! 🎉'
                                    : 'Daily Goal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: progress.goalMetToday 
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                progress.goalMetToday
                                    ? 'Great job! Keep it up tomorrow!'
                                    : '${progress.formatSteps(progress.stepsRemaining)} steps to go',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit goal button
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          color: AppTheme.textMuted,
                          onPressed: () => _showGoalSettingsDialog(context, game),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Streak row
                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.local_fire_department_rounded,
                          value: '${progress.currentStreak}',
                          label: 'Day Streak',
                          color: AppTheme.accentPink,
                        ),
                        const SizedBox(width: 16),
                        _MiniStat(
                          icon: Icons.emoji_events_rounded,
                          value: '${progress.longestStreak}',
                          label: 'Best Streak',
                          color: AppTheme.accentGold,
                        ),
                        const SizedBox(width: 16),
                        _MiniStat(
                          icon: Icons.calendar_today_rounded,
                          value: '${progress.totalGoalDaysCompleted}',
                          label: 'Goals Met',
                          color: AppTheme.secondaryTeal,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pets_rounded,
                      value: '${game.pets.length}',
                      label: 'Pets',
                      color: AppTheme.secondaryTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.egg_rounded,
                      value: '${activeEggs.length}',
                      label: 'Eggs',
                      color: AppTheme.accentGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.directions_walk_rounded,
                      value: _formatSteps(progress.totalStepsAllTime),
                      label: 'Total Steps',
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),

              // Hatchable eggs notification
              if (hatchableEggs.isNotEmpty) ...[
                _HatchNotification(
                  count: hatchableEggs.length,
                  onTap: () {
                    // Navigate to incubation tab
                    DefaultTabController.of(context).animateTo(2);
                  },
                ).animate().fadeIn(delay: 400.ms).shimmer(
                      duration: 2000.ms,
                      color: AppTheme.accentGold.withOpacity(0.3),
                    ),
                const SizedBox(height: 24),
              ],

              // Active eggs preview
              if (activeEggs.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Incubating',
                  onSeeAll: () {
                    DefaultTabController.of(context).animateTo(2);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: activeEggs.length.clamp(0, 3),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final egg = activeEggs[index];
                      return SizedBox(
                        width: 150,
                        child: EggCard(
                          egg: egg,
                          onHatch: egg.canHatch
                              ? () => _showHatchDialog(context, game, egg)
                              : null,
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],

              const SizedBox(height: 24),

              // Pets preview
              if (game.pets.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Your Pets',
                  onSeeAll: () {
                    DefaultTabController.of(context).animateTo(3);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: game.pets.length.clamp(0, 5),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 80,
                        child: PetCard(
                          pet: game.pets[index],
                          compact: true,
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],

              const SizedBox(height: 32),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _showHatchDialog(BuildContext context, GameProvider game, egg) async {
    final pet = await game.hatchEgg(egg);
    if (pet != null && context.mounted) {
      // Play hatch celebration sound
      context.read<SoundService>().playHatchCelebration();
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _HatchSuccessDialog(pet: pet),
      );
    }
  }
  
  void _showGoalSettingsDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (context) => _GoalSettingsDialog(
        currentGoal: game.progress.dailyStepGoal,
        onSave: (newGoal) {
          game.setDailyGoal(newGoal);
        },
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000000) {
      return '${(steps / 1000000).toStringAsFixed(1)}M';
    } else if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}K';
    }
    return steps.toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _HatchNotification extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _HatchNotification({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentGold, Color(0xFFFFB74D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.glowShadow(AppTheme.accentGold),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.egg_alt_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count egg${count > 1 ? 's' : ''} ready to hatch!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Tap to hatch your new pet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all'),
          ),
      ],
    );
  }
}

class _HatchSuccessDialog extends StatelessWidget {
  final Pet pet;

  const _HatchSuccessDialog({required this.pet});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Dialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: AppTheme.accentGold,
                size: 48,
              )
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(),
              const SizedBox(height: 16),
              Text(
                'Congratulations!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You hatched a new pet!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              PetCard(pet: pet, showLevel: false),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Small delay to prevent tap from propagating to underlying widgets
                    await Future.delayed(const Duration(milliseconds: 50));
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Awesome!'),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalSettingsDialog extends StatefulWidget {
  final int currentGoal;
  final Function(int) onSave;

  const _GoalSettingsDialog({
    required this.currentGoal,
    required this.onSave,
  });

  @override
  State<_GoalSettingsDialog> createState() => _GoalSettingsDialogState();
}

class _GoalSettingsDialogState extends State<_GoalSettingsDialog> {
  late int _selectedGoal;
  
  static const List<int> _presetGoals = [1000, 2500, 5000, 7500, 10000, 15000, 20000];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoal;
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
            const Icon(
              Icons.flag_rounded,
              color: AppTheme.primaryGreen,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Set Daily Goal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your daily step target',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _presetGoals.map((goal) {
                final isSelected = goal == _selectedGoal;
                return ChoiceChip(
                  label: Text('${goal ~/ 1000}k'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedGoal = goal),
                  backgroundColor: AppTheme.backgroundLight,
                  selectedColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              '${_selectedGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps/day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_selectedGoal);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
