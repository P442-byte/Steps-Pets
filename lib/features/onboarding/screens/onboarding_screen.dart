import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_monster.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Welcome to\nSteps & Pets!',
      description: 'Walk, hatch eggs, and collect adorable pets. Your steps power your journey!',
      icon: Icons.pets_rounded,
      color: AppTheme.primaryGreen,
      monsterType: null,
    ),
    _OnboardingPage(
      title: 'Walk to\nHatch Eggs',
      description: 'Every step you take helps incubate your eggs. The more you walk, the faster they hatch!',
      icon: Icons.egg_rounded,
      color: AppTheme.accentGold,
      monsterType: null,
      showEgg: true,
    ),
    _OnboardingPage(
      title: 'Collect\nUnique Pets',
      description: 'Discover pets of different types and rarities. Rare pets have special sparkle effects!',
      icon: Icons.catching_pokemon_rounded,
      color: AppTheme.secondaryTeal,
      monsterType: MonsterType.water,
    ),
    _OnboardingPage(
      title: 'Watch Them\nGrow',
      description: 'Your pets level up as you walk together. Visit the garden to see them roam around!',
      icon: Icons.park_rounded,
      color: AppTheme.accentPink,
      monsterType: MonsterType.fire,
    ),
    _OnboardingPage(
      title: 'Set Your\nDaily Goal',
      description: 'Choose a step goal that works for you. Build streaks by meeting your goal every day!',
      icon: Icons.flag_rounded,
      color: AppTheme.primaryGreen,
      monsterType: null,
      showGoalSelector: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.completeOnboarding();
    context.read<SoundService>().playHatchCelebration();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    context.read<SoundService>().play(SoundType.buttonTap);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _pages[_currentPage].color
                            : AppTheme.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? "Let's Go!" : 'Next',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual element
          SizedBox(
            height: 200,
            child: _buildVisual(page),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.8, 0.8),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

          // Goal selector (only on last page)
          if (page.showGoalSelector) ...[
            const SizedBox(height: 32),
            _buildGoalSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildVisual(_OnboardingPage page) {
    if (page.monsterType != null) {
      return AnimatedMonster(
        type: page.monsterType!,
        size: 150,
        rarityLevel: page.monsterType == MonsterType.fire ? 3 : 0,
      );
    }

    if (page.showEgg) {
      return AnimatedMonster(
        type: MonsterType.spirit,
        size: 120,
        isEgg: true,
        hatchProgress: 0.7,
      );
    }

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: page.color.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: page.color.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Icon(
        page.icon,
        size: 80,
        color: page.color,
      ),
    );
  }

  Widget _buildGoalSelector() {
    final gameProvider = context.watch<GameProvider>();
    final currentGoal = gameProvider.progress.dailyStepGoal;
    const goals = [2500, 5000, 7500, 10000];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: goals.map((goal) {
        final isSelected = goal == currentGoal;
        return GestureDetector(
          onTap: () {
            gameProvider.setDailyGoal(goal);
            context.read<SoundService>().play(SoundType.buttonTap);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.backgroundLight,
                width: 2,
              ),
            ),
            child: Text(
              '${goal ~/ 1000}k',
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final MonsterType? monsterType;
  final bool showEgg;
  final bool showGoalSelector;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.monsterType,
    this.showEgg = false,
    this.showGoalSelector = false,
  });
}




