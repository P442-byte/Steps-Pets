import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:steps_and_pets/core/providers/providers.dart';
import 'package:steps_and_pets/core/services/sound_service.dart';
import 'package:steps_and_pets/core/theme/app_theme.dart';
import 'package:steps_and_pets/features/home/screens/home_screen.dart';
import 'package:steps_and_pets/features/incubation/screens/incubation_screen.dart';
import 'package:steps_and_pets/features/onboarding/screens/onboarding_screen.dart';
import 'package:steps_and_pets/features/pets/screens/pets_screen.dart';
import 'package:steps_and_pets/features/garden/screens/garden_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Logo/Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Steps & Pets',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Settings button
                      IconButton(
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => _showSettings(context),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.3),

                // Content
                Expanded(
                  child: TabBarView(
                    children: const [
                      HomeScreen(),
                      GardenScreen(),
                      IncubationScreen(),
                      PetsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomNav(),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _SettingsSheet(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundMedium,
        border: Border(
          top: BorderSide(
            color: AppTheme.backgroundLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: TabBar(
          indicatorColor: AppTheme.accentGold,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontSize: 11),
          tabs: const [
            Tab(
              icon: Icon(Icons.home_rounded, size: 22),
              text: 'Home',
            ),
            Tab(
              icon: Icon(Icons.park_rounded, size: 22),
              text: 'Garden',
            ),
            Tab(
              icon: Icon(Icons.egg_rounded, size: 22),
              text: 'Eggs',
            ),
            Tab(
              icon: Icon(Icons.catching_pokemon_rounded, size: 22),
              text: 'Pets',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  static const List<int> _goalPresets = [1000, 2500, 5000, 7500, 10000, 15000, 20000];

  @override
  Widget build(BuildContext context) {
    final soundService = context.read<SoundService>();
    final gameProvider = context.watch<GameProvider>();
    final progress = gameProvider.progress;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Sound toggle
            _SettingsToggle(
              icon: Icons.volume_up_rounded,
              title: 'Sound Effects',
              subtitle: 'Play sounds for actions',
              value: soundService.soundEnabled,
              onChanged: (value) {
                setState(() {
                  soundService.setSoundEnabled(value);
                });
                if (value) {
                  soundService.play(SoundType.buttonTap);
                }
              },
            ),
            
            const Divider(height: 32),
            
            // Daily Goal Section
            Text(
              'Daily Step Goal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${_formatNumber(progress.dailyStepGoal)} steps',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalPresets.map((goal) {
                final isSelected = goal == progress.dailyStepGoal;
                return ChoiceChip(
                  label: Text('${goal ~/ 1000}k'),
                  selected: isSelected,
                  onSelected: (_) {
                    gameProvider.setDailyGoal(goal);
                    soundService.play(SoundType.buttonTap);
                  },
                  backgroundColor: AppTheme.backgroundLight,
                  selectedColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            
            const Divider(height: 32),

            // Other settings
            _SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              subtitle: 'Coming soon',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications coming in a future update!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.health_and_safety_rounded,
              title: 'Health Permissions',
              subtitle: 'Manage step tracking access',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Health permissions can be managed in device settings'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Reset Progress',
              subtitle: 'Clear all data and start fresh',
              color: AppTheme.accentPink,
              onTap: () => _showResetConfirmation(context, gameProvider),
            ),
            
            const Divider(height: 32),
            
            // Debug/Testing Section
            Text(
              '🧪 Debug & Testing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Developer tools for testing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            
            // Add steps buttons
            Row(
              children: [
                Expanded(
                  child: _DebugButton(
                    label: '+50 Steps',
                    icon: Icons.directions_walk,
                    onTap: () {
                      gameProvider.addMockSteps(50);
                      soundService.play(SoundType.buttonTap);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added 50 steps'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DebugButton(
                    label: '+500 Steps',
                    icon: Icons.directions_run,
                    onTap: () {
                      gameProvider.addMockSteps(500);
                      soundService.play(SoundType.buttonTap);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added 500 steps'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DebugButton(
                    label: '+5000',
                    icon: Icons.rocket_launch,
                    onTap: () {
                      gameProvider.addMockSteps(5000);
                      soundService.play(SoundType.buttonTap);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added 5000 steps'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _SettingsTile(
              icon: Icons.school_rounded,
              title: 'Show Onboarding',
              subtitle: 'View the welcome tutorial again',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showOnboarding(context);
              },
            ),
            _SettingsTile(
              icon: Icons.egg_rounded,
              title: 'Add Test Egg',
              subtitle: 'Get a random egg for testing',
              color: Colors.orange,
              onTap: () {
                gameProvider.addTestEgg();
                soundService.play(SoundType.eggReceived);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added a test egg!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.pets_rounded,
              title: 'Add Test Pet',
              subtitle: 'Get a random pet for testing',
              color: Colors.orange,
              onTap: () {
                gameProvider.addTestPet();
                soundService.playHatchCelebration();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added a test pet!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            
            const Divider(height: 32),
            
            // About & Quit
            _SettingsTile(
              icon: Icons.info_rounded,
              title: 'About',
              subtitle: 'Steps & Pets v1.0.0',
              onTap: () => _showAboutDialog(context),
            ),
            _SettingsTile(
              icon: Icons.exit_to_app_rounded,
              title: 'Quit App',
              subtitle: 'Close the application',
              color: Colors.grey,
              onTap: () => _showQuitConfirmation(context),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
  
  void _showResetConfirmation(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will delete all your pets, eggs, and progress. This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close settings
              await gameProvider.resetAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All progress has been reset'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pets_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Steps & Pets'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 12),
            Text(
              'Walk to hatch eggs and collect adorable pets! '
              'Stay active and grow your collection.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 Steps & Pets',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showQuitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Quit App?'),
        content: const Text('Are you sure you want to close the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // Exit the app
              SystemNavigator.pop();
            },
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
  
  void _showOnboarding(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.secondaryTeal).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color ?? AppTheme.secondaryTeal,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
            ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textMuted,
      ),
      onTap: onTap,
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.secondaryTeal.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.secondaryTeal,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
            ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DebugButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.orange, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
