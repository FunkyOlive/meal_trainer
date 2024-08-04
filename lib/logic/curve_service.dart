import 'dart:math';
import 'package:meal_trainer/datamodels/meal.dart';

/// Written directly after MealTrainerCore
class LegacyCurveService {
  late double linearFactor, quadraticFactor;

  Duration targetMealLength;
  int targetMealSize;
  int initialBiteSize;

  LegacyCurveService({
    required this.targetMealLength,
    required this.targetMealSize,
    required this.initialBiteSize,
  }) {
    linearFactor = _findLinearFactorForMinimalTargetDifference();
    quadraticFactor = _getQuadraticFactor(
      linearFactor,
      targetMealLength.inMinutes,
    );
  }

  int getCurrentSecondsTilNextBite(int currentTimeSeconds) {
    final double decimalMinutes = currentTimeSeconds / 60.0;
    final double estimateFoodConsumed =
        targetEatenWeightFromDecMinutes(decimalMinutes);
    final double foodConsumedIn1Minute =
        targetEatenWeightFromDecMinutes(decimalMinutes + 1);
    final double consumptionDelta =
        foodConsumedIn1Minute - estimateFoodConsumed;
    final double bitesNeeded = max(consumptionDelta / initialBiteSize, 1.0);
    final double timePerBite = 60.0 / bitesNeeded;
    return timePerBite.toInt();
  }

  double targetEatenWeightFromDecMinutes(double decimalMinutes) {
    return (quadraticFactor * pow(decimalMinutes, 2) +
        linearFactor * decimalMinutes);
  }

  double _getQuadraticFactor(double linearFactor, int durationMinutes) {
    return -1 * (linearFactor / (2 * durationMinutes));
  }

  double _findLinearFactorForMinimalTargetDifference() {
    final List<double> B = _linspace(50, 150, 100);
    final List<double> diffs = _getDiffs(B);
    final double minDiff = _minValue(diffs);
    if (minDiff > 1) {
      print('[WARNING]: Cannot estimate target weight to within 1g'
          '. \nMinimum absolute difference to target weight $minDiff g'
          ' for duration ${targetMealLength.inMinutes} min'
          ' is $targetMealSize g.');
    }
    return B[diffs.indexOf(minDiff)];
  }

  List<double> _getDiffs(List<double> bValues) {
    List<double> out = List.filled(bValues.length, -1);
    final double target = targetMealSize.toDouble();
    final int duration = targetMealLength.inMinutes;
    for (int i = 0; i < bValues.length; i++) {
      out[i] = (target -
              (_getQuadraticFactor(bValues[i], duration) *
                  (pow(duration, 2) + bValues[i] * duration)))
          .abs();
    }
    return out;
  }

  List<double> _linspace(int min, int max, int points) {
    return List.generate(
      points,
      (i) => min + i * (max - min) / (points - 1),
    );
  }

  double _minValue(List<double> values) {
    double currentMin = values[0];
    for (double value in values) {
      if (value < currentMin) {
        currentMin = value;
      }
    }
    return currentMin;
  }
}

class CurveService {
  FinalMealInfo finalMealInfo;

  CurveService(this.finalMealInfo);

  Duration getTimeBetweenBites(Duration timeElapsed) {
    final double decimalMinutesElapsed = timeElapsed.inSeconds / 60;

    final int weightTargetDifferenceThisMinute =
        targetRemainingWeightFromDecMinutes(decimalMinutesElapsed + 1) -
            targetRemainingWeightFromDecMinutes(decimalMinutesElapsed);
    final double biteTargetThisMinute = max(1,
        (weightTargetDifferenceThisMinute / (finalMealInfo.initialBiteSize!)));
    final double secondsPerBite = 60 / biteTargetThisMinute;
    return Duration(seconds: secondsPerBite.round());
  }

  int targetRemainingWeightFromDecMinutes(num decimalMinutesElapsed) {
    var quadraticFactor = finalMealInfo.quadraticFactor;
    var linearFactor = finalMealInfo.linearFactor;

    var targetWeight = ((quadraticFactor) * (pow(decimalMinutesElapsed, 2)) +
        ((linearFactor) * decimalMinutesElapsed));
    return targetWeight.toInt();
  }

  int? targetEatenWeigthFromDecMinutes(num decimalMinutesElapsed) {
    if (finalMealInfo.targetMealSize == null) {
      return null;
    }
    return finalMealInfo.targetMealSize! -
        targetRemainingWeightFromDecMinutes(decimalMinutesElapsed);
  }
}
