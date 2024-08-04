import 'dart:core';
import 'package:hive/hive.dart';

import 'package:meal_trainer/logic/curve_service.dart';

part 'meal.g.dart';

@HiveType(typeId: 1)
class FinalMealInfo {
  @HiveField(0)
  final DateTime startedAt;

  @HiveField(1)
  final String eatingPatient;
  @HiveField(2)
  final int? initialBiteSize;
  @HiveField(3)
  final Duration targetMealLength;
  @HiveField(4)
  final int? targetMealSize;

  late final double linearFactor;
  late final double quadraticFactor;

  FinalMealInfo({
    this.targetMealSize,
    required this.targetMealLength,
    required this.eatingPatient,
    this.initialBiteSize,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now() {
    LegacyCurveService? lCurveService;
    if (initialBiteSize != null && targetMealSize != null) {
      lCurveService = LegacyCurveService(
        initialBiteSize: initialBiteSize!,
        targetMealLength: targetMealLength,
        targetMealSize: targetMealSize!,
      );
    } else {
      print('initialBiteSize is $initialBiteSize'
          ', targetMealSize is $targetMealSize'
          '. Falling back to default factors');
    }
    linearFactor = lCurveService?.linearFactor ?? 50.002;
    quadraticFactor = lCurveService?.quadraticFactor ?? -1.7858;

    //TODO offer manual override?
    //TODO cache in Map?
  }
}

abstract class RecordedMeal {
  @HiveField(3)
  final DateTime endedAt;

  @HiveField(50)
  final FinalMealInfo finalMealInfo;

  RecordedMeal({
    required this.endedAt,
    required this.finalMealInfo,
  });

  static Map<Duration, int> dummyTargetWeights = {
    const Duration(minutes: 0): 0,
    const Duration(minutes: 14): 350
  };
  static Map<Duration, int> dummyMeasuredWeights = {
    const Duration(minutes: 1): 64,
    const Duration(minutes: 7): 286,
    const Duration(minutes: 13): 311
  };
}

@HiveType(typeId: 4)
class RecordedUnmeasuredMeal extends RecordedMeal {
  RecordedUnmeasuredMeal(
      {required super.endedAt, required super.finalMealInfo});
}

@HiveType(typeId: 5)
class RecordedMeasuredMeal extends RecordedMeal {
  /// Mapping x time to y targetWeight and y measuredWeight
  @HiveField(0)
  final Map<Duration, int> targetWeights;
  @HiveField(1)
  final Map<Duration, int> measuredWeights;

  @HiveField(2)
  final int? measuredBiteSize;

  RecordedMeasuredMeal(
      {required this.targetWeights,
      required this.measuredWeights,
      required this.measuredBiteSize,
      required super.endedAt,
      required super.finalMealInfo});
}

@HiveType(typeId: 6)
class RecordedCalibrationMeal extends RecordedMeal {
  /// Mapping x time to y measuredWeight
  @HiveField(1)
  final Map<Duration, int> measuredWeights;

  @HiveField(2)
  final int? measuredBiteSize;

  RecordedCalibrationMeal(
      {required this.measuredWeights,
      required this.measuredBiteSize,
      required super.finalMealInfo,
      required super.endedAt});
}
