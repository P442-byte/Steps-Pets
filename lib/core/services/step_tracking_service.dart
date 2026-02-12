import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

enum StepTrackingStatus {
  notInitialized,
  permissionDenied,
  available,
  unavailable,
}

class StepTrackingService {
  final Health _health = Health();
  
  StepTrackingStatus _status = StepTrackingStatus.notInitialized;
  StepTrackingStatus get status => _status;

  int _todaySteps = 0;
  int get todaySteps => _todaySteps;

  DateTime? _lastFetchTime;

  // Types we want to read
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
  ];

  /// Initialize the health service and request permissions
  Future<bool> initialize() async {
    try {
      // Check if health data is available on this platform
      if (kIsWeb) {
        _status = StepTrackingStatus.unavailable;
        return false;
      }

      // Request activity recognition permission (needed for steps on Android)
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) {
        _status = StepTrackingStatus.permissionDenied;
        return false;
      }

      // Configure health
      await _health.configure();

      // Request authorization for health data
      final permissions = _types.map((e) => HealthDataAccess.READ).toList();
      final authorized = await _health.requestAuthorization(
        _types,
        permissions: permissions,
      );

      if (authorized) {
        _status = StepTrackingStatus.available;
        await fetchTodaySteps();
        return true;
      } else {
        _status = StepTrackingStatus.permissionDenied;
        return false;
      }
    } catch (e) {
      debugPrint('Error initializing step tracking: $e');
      _status = StepTrackingStatus.unavailable;
      return false;
    }
  }

  /// Fetch today's step count
  Future<int> fetchTodaySteps() async {
    if (_status != StepTrackingStatus.available) {
      return _todaySteps;
    }

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // Get step count for today
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      
      _todaySteps = steps ?? 0;
      _lastFetchTime = now;

      return _todaySteps;
    } catch (e) {
      debugPrint('Error fetching steps: $e');
      return _todaySteps;
    }
  }

  /// Fetch steps for a specific date range
  Future<int> fetchStepsInRange(DateTime start, DateTime end) async {
    if (_status != StepTrackingStatus.available) {
      return 0;
    }

    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      debugPrint('Error fetching steps in range: $e');
      return 0;
    }
  }

  /// Get steps since last fetch (for incremental updates)
  Future<int> fetchStepsSinceLastUpdate() async {
    if (_status != StepTrackingStatus.available || _lastFetchTime == null) {
      return await fetchTodaySteps();
    }

    try {
      final now = DateTime.now();
      final steps = await _health.getTotalStepsInInterval(_lastFetchTime!, now);
      
      if (steps != null && steps > 0) {
        _todaySteps += steps;
        _lastFetchTime = now;
      }

      return steps ?? 0;
    } catch (e) {
      debugPrint('Error fetching incremental steps: $e');
      return 0;
    }
  }

  /// Check if we have permission to read health data
  Future<bool> hasPermission() async {
    try {
      final result = await _health.hasPermissions(_types);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open health app settings
  Future<void> openHealthSettings() async {
    await openAppSettings();
  }
}

/// Mock service for testing/development without health APIs
class MockStepTrackingService extends StepTrackingService {
  int _mockSteps = 0;

  @override
  StepTrackingStatus get status => StepTrackingStatus.available;

  @override
  int get todaySteps => _mockSteps;

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<int> fetchTodaySteps() async {
    return _mockSteps;
  }

  /// Add mock steps (for testing)
  void addMockSteps(int steps) {
    _mockSteps += steps;
  }

  /// Set mock steps directly
  void setMockSteps(int steps) {
    _mockSteps = steps;
  }

  /// Reset mock steps
  void resetMockSteps() {
    _mockSteps = 0;
  }
}

