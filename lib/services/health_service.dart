import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart' as health_pkg;
import '../models/health_data_models.dart' as models;

/// Service for integrating with device health data (Apple Health / Google Health Connect)
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final health_pkg.Health _health = health_pkg.Health();
  bool _isInitialized = false;
  bool _hasPermissions = false;

  /// Health data types we want to read
  static final List<health_pkg.HealthDataType> _dataTypes = [
    health_pkg.HealthDataType.STEPS,
    health_pkg.HealthDataType.SLEEP_ASLEEP,
    health_pkg.HealthDataType.SLEEP_IN_BED,
    health_pkg.HealthDataType.HEART_RATE,
    health_pkg.HealthDataType.ACTIVE_ENERGY_BURNED,
    health_pkg.HealthDataType.WORKOUT,
  ];

  /// Check if health integration is available on this platform
  bool get isAvailable => Platform.isIOS || Platform.isAndroid;

  /// Check if we have permissions
  bool get hasPermissions => _hasPermissions;

  /// Initialize the health service
  Future<void> initialize() async {
    if (_isInitialized || !isAvailable) return;

    try {
      // Configure health package
      await _health.configure();
      _isInitialized = true;
      debugPrint('HealthService initialized');
    } catch (e) {
      debugPrint('Error initializing HealthService: $e');
    }
  }

  /// Request permissions to access health data
  /// Returns a record with granted status and optional error message
  Future<({bool granted, String? error})> requestPermissions() async {
    if (!isAvailable) {
      return (granted: false, error: 'Health integration is not available on this platform');
    }

    try {
      await initialize();

      // On Android, check Health Connect SDK status first
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        debugPrint('Health Connect SDK status: $status');

        if (status == health_pkg.HealthConnectSdkStatus.sdkUnavailable) {
          return (
            granted: false,
            error: 'INSTALL_HEALTH_CONNECT',
          );
        }

        if (status == health_pkg.HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          return (
            granted: false,
            error: 'INSTALL_HEALTH_CONNECT',
          );
        }
      }

      // Request authorization
      final permissions = _dataTypes.map((type) => health_pkg.HealthDataAccess.READ).toList();
      final authorized = await _health.requestAuthorization(
        _dataTypes,
        permissions: permissions,
      );

      _hasPermissions = authorized;
      debugPrint('Health permissions granted: $authorized');

      if (!authorized) {
        return (
          granted: false,
          error: 'Health permissions were denied. Please enable them in ${Platform.isIOS ? 'Apple Health' : 'Health Connect'} settings.',
        );
      }

      return (granted: true, error: null);
    } catch (e) {
      debugPrint('Error requesting health permissions: $e');
      return (granted: false, error: 'Failed to request health permissions: $e');
    }
  }

  /// Check current permission status
  Future<bool> checkPermissions() async {
    if (!isAvailable) return false;

    try {
      await initialize();

      // Try to check if we have permissions by checking authorization status
      final hasPermission = await _health.hasPermissions(
        _dataTypes,
        permissions: _dataTypes.map((type) => health_pkg.HealthDataAccess.READ).toList(),
      );

      _hasPermissions = hasPermission ?? false;
      return _hasPermissions;
    } catch (e) {
      debugPrint('Error checking health permissions: $e');
      return false;
    }
  }

  /// Get health data for a specific date
  Future<models.HealthDataPoint?> getHealthDataForDate(DateTime date) async {
    if (!_hasPermissions || !isAvailable) return null;

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: _dataTypes,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      if (healthData.isEmpty) {
        return models.HealthDataPoint(date: date);
      }

      // Aggregate the data
      int? steps;
      double? sleepHours;
      int? heartRate;
      int? activeMinutes;
      int? caloriesBurned;

      final stepPoints = healthData.where((p) => p.type == health_pkg.HealthDataType.STEPS);
      if (stepPoints.isNotEmpty) {
        int totalSteps = 0;
        for (final point in stepPoints) {
          // Type-safe check before casting
          if (point.value is health_pkg.NumericHealthValue) {
            totalSteps += (point.value as health_pkg.NumericHealthValue).numericValue.toInt();
          }
        }
        steps = totalSteps;
      }

      // Calculate sleep from sleep data
      final sleepPoints = healthData.where(
        (p) => p.type == health_pkg.HealthDataType.SLEEP_ASLEEP || p.type == health_pkg.HealthDataType.SLEEP_IN_BED,
      );
      if (sleepPoints.isNotEmpty) {
        double totalSleepMinutes = 0;
        for (final point in sleepPoints) {
          final duration = point.dateTo.difference(point.dateFrom);
          totalSleepMinutes += duration.inMinutes;
        }
        sleepHours = totalSleepMinutes / 60;
      }

      // Get average heart rate
      final heartRatePoints = healthData.where((p) => p.type == health_pkg.HealthDataType.HEART_RATE);
      if (heartRatePoints.isNotEmpty) {
        final values = <int>[];
        for (final point in heartRatePoints) {
          // Type-safe check before casting
          if (point.value is health_pkg.NumericHealthValue) {
            values.add((point.value as health_pkg.NumericHealthValue).numericValue.toInt());
          }
        }
        if (values.isNotEmpty) {
          heartRate = values.reduce((a, b) => a + b) ~/ values.length;
        }
      }

      // Calculate active minutes from workouts
      final workoutPoints = healthData.where((p) => p.type == health_pkg.HealthDataType.WORKOUT);
      if (workoutPoints.isNotEmpty) {
        int totalMinutes = 0;
        for (final point in workoutPoints) {
          totalMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
        }
        activeMinutes = totalMinutes;
      }

      // Get calories burned
      final caloriePoints = healthData.where((p) => p.type == health_pkg.HealthDataType.ACTIVE_ENERGY_BURNED);
      if (caloriePoints.isNotEmpty) {
        int totalCalories = 0;
        for (final point in caloriePoints) {
          // Type-safe check before casting
          if (point.value is health_pkg.NumericHealthValue) {
            totalCalories += (point.value as health_pkg.NumericHealthValue).numericValue.toInt();
          }
        }
        caloriesBurned = totalCalories;
      }

      return models.HealthDataPoint(
        date: date,
        steps: steps,
        sleepHours: sleepHours,
        sleepQuality: _getSleepQuality(sleepHours),
        heartRate: heartRate,
        activeMinutes: activeMinutes,
        caloriesBurned: caloriesBurned,
      );
    } catch (e) {
      debugPrint('Error getting health data for date: $e');
      return null;
    }
  }

  /// Get health data for a date range
  Future<List<models.HealthDataPoint>> getHealthDataForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasPermissions || !isAvailable) return [];

    final dataPoints = <models.HealthDataPoint>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final data = await getHealthDataForDate(currentDate);
      if (data != null) {
        dataPoints.add(data);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dataPoints;
  }

  /// Get health data summary for the last N days
  Future<models.HealthDataSummary> getHealthSummary({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final dataPoints = await getHealthDataForRange(
      startDate: startDate,
      endDate: endDate,
    );

    return models.HealthDataSummary.fromDataPoints(dataPoints);
  }

  /// Get today's health data
  Future<models.HealthDataPoint?> getTodaysHealthData() async {
    return getHealthDataForDate(DateTime.now());
  }

  /// Convert sleep hours to quality rating
  String _getSleepQuality(double? hours) {
    if (hours == null) return 'Unknown';
    if (hours >= 7.5) return 'Excellent';
    if (hours >= 7) return 'Good';
    if (hours >= 6) return 'Fair';
    return 'Poor';
  }

  /// Prepare health data for AI analysis
  Future<List<Map<String, dynamic>>> prepareHealthDataForAnalysis({
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final dataPoints = await getHealthDataForRange(
      startDate: startDate,
      endDate: endDate,
    );

    return dataPoints.map((point) => point.toJson()).toList();
  }

  /// Revoke health permissions (user wants to disconnect)
  Future<void> revokePermissions() async {
    // Note: Most platforms don't allow programmatic permission revocation
    // User must go to system settings to revoke
    _hasPermissions = false;
    debugPrint('Health permissions marked as revoked - user should revoke in system settings');
  }
}
