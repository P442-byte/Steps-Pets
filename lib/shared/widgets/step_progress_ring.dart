import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StepProgressRing extends StatelessWidget {
  final double progress;
  final int currentSteps;
  final int goalSteps;
  final double size;
  final double strokeWidth;

  const StepProgressRing({
    super.key,
    required this.progress,
    required this.currentSteps,
    required this.goalSteps,
    this.size = 200,
    this.strokeWidth = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                AppTheme.backgroundLight.withOpacity(0.5),
              ),
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accentGold),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: AppTheme.accentGold,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                _formatNumber(currentSteps),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              Text(
                'of ${_formatNumber(goalSteps)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

