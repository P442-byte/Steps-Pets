import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/providers/providers.dart';
import 'core/services/services.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundMedium,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const StepsAndPetsApp());
}

class StepsAndPetsApp extends StatelessWidget {
  const StepsAndPetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>(
          create: (_) => StorageService(),
          dispose: (_, service) => service.close(),
        ),
        Provider<StepTrackingService>(
          // Use MockStepTrackingService for development/testing
          // Switch to StepTrackingService() for production with real health data
          create: (_) => MockStepTrackingService(),
        ),
        Provider<SoundService>(
          create: (_) {
            final service = SoundService();
            service.initialize();
            return service;
          },
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProxyProvider2<StorageService, StepTrackingService,
            GameProvider>(
          create: (context) => GameProvider(
            storage: context.read<StorageService>(),
            stepService: context.read<StepTrackingService>(),
          ),
          update: (context, storage, stepService, previous) =>
              previous ??
              GameProvider(
                storage: storage,
                stepService: stepService,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Steps & Pets',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppLoader(),
      ),
    );
  }
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _isLoading = true;
  bool _showOnboarding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final gameProvider = context.read<GameProvider>();
      await gameProvider.initialize();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showOnboarding = !gameProvider.hasCompletedOnboarding;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LoadingScreen();
    }

    if (_error != null) {
      return _ErrorScreen(error: _error!, onRetry: _initializeApp);
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() => _showOnboarding = false);
        },
      );
    }

    return const MainShell();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.glowShadow(AppTheme.primaryGreen),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Steps & Pets',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Walk. Hatch. Collect.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: AppTheme.accentGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppTheme.accentPink,
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Something went wrong while loading the app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
