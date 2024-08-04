import 'dart:math';

import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/logic/curve_service.dart';
import 'package:meal_trainer/logic/storage_service.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:meal_trainer/ui/ui_components.dart';

// TODO move to util file
Duration roundToSeconds(Duration dur) {
  return Duration(seconds: dur.inSeconds);
}

enum MealStatus {
  prepared,
  running,
  timeout,
  ended,
  overtime,
}

class MealService extends ChangeNotifier {
  RunningMeal? runningMeal;
  Timer? mealTimer;

  MealStatus mealStatus =
      MealStatus.prepared; // TODO add setter for prepareMeal and make private?

  @override
  String toString() {
    // TODO move out of logic
    switch (mealStatus) {
      case MealStatus.prepared:
        return 'Meal is prepared. No meal in progress.';
      // TODO give finalMealInfo.patient
      case MealStatus.running:
        return 'Patient ${runningMeal!.finalMealInfo.eatingPatient}'
            ' is eating since ${toTimeString(runningMeal!.finalMealInfo.startedAt).substring(14, 19)}'
            '.';
      case MealStatus.timeout:
      case MealStatus.ended:
        return 'Meal has ended.';
      case MealStatus.overtime:
        return 'Patient ${runningMeal!.finalMealInfo.eatingPatient}'
            ' is eating since ${toTimeString(runningMeal!.finalMealInfo.startedAt).substring(14, 19)}'
            '.\n\nThe meal length has passed. Use Abort to finish.';
    }
  }

  startMeal(FinalMealInfo finalMealInfo, Type mealType) {
    assert(mealStatus == MealStatus.prepared);

    switch (mealType) {
      case RunningCalibrationMeal:
        runningMeal = RunningCalibrationMeal(finalMealInfo);
        break;
      case RunningUnmeasuredMeal:
        runningMeal = RunningUnmeasuredMeal(finalMealInfo);
        break;
      case RunningMeasuredMeal:
        runningMeal = RunningMeasuredMeal(finalMealInfo);
        break;
      default:
        throw Exception('Unknown Subtype of RunningMeal: $mealType');
    }
    runningMeal!.addListener(() => notifyListeners());

    var mealLength = finalMealInfo.targetMealLength;
    print('starting mealTimer for ${mealLength.inSeconds} seconds');
    mealTimer = Timer(mealLength, () {
      mealStatus = MealStatus.timeout;
      notifyListeners();
    });

    mealStatus = MealStatus.running;
    notifyListeners();
  }

  RecordedMeal endMeal() {
    assert(mealStatus == MealStatus.running ||
        mealStatus == MealStatus.timeout ||
        mealStatus == MealStatus.overtime);
    pauseMeal();

    var endedMeal = runningMeal!.storeMeal();
    runningMeal!.dispose();
    runningMeal = null;

    mealStatus = MealStatus.ended;
    //notifyListeners();
    return endedMeal;
  }

  /// return updated self on updates of listened-to provider(s)
  MealService update(int measuredWeightOnBite) {
    switch (runningMeal.runtimeType) {
      case RunningMeasuredMeal:
        (runningMeal as RunningMeasuredMeal).update(measuredWeightOnBite);
        break;
      case RunningCalibrationMeal:
        (runningMeal as RunningCalibrationMeal).update(measuredWeightOnBite);
        break;
    }
    return this;
  }

  void pauseMeal() {
    // _mealStatus = MealStatus.paused;
    // TODO add pause timestamps to meal
    // TODO update duration logic to exclude those
    // TODO display pauses in graph
    // TODO pause Timers (meal, bite, biteAnimation)
    // TODO disable measurement recording. reenable on resume.
    // TODO add pause buttons on running meal pages
  }
}

abstract class RunningMeal extends ChangeNotifier {
  final FinalMealInfo finalMealInfo;

  RunningMeal(this.finalMealInfo);

  Duration get timeElapsed =>
      roundToSeconds(DateTime.now().difference(finalMealInfo.startedAt));

  RecordedMeal storeMeal();
}

class RunningCalibrationMeal extends RunningMeal {
  final Map<Duration, int> _measuredWeights = {};

  Map<Duration, int> get measuredWeights => _measuredWeights;

  RunningCalibrationMeal(super.finalMealInfo);

  addMeasuredWeight(int value) {
    //TODO shoud timestamp for measured weight be set here?
    var time = timeElapsed;
    _measuredWeights[time] = value;
    print('added weight $value at time $time');
    notifyListeners();
  }

  @override
  storeMeal() {
    var meal = RecordedCalibrationMeal(
        finalMealInfo: finalMealInfo,
        measuredWeights: _measuredWeights,
        measuredBiteSize: computeBiteSizeFromWeights(
            _measuredWeights), //TODO compute and show live/changing biteSize during meal
        endedAt: DateTime.now());
    StorageService.putMeal(meal);
    return meal;
  }

  int? computeBiteSizeFromWeights(Map<Duration, int> measuredWeights) {
    if (measuredWeights.length < 2) {
      return null;
    }

    var weights = measuredWeights.values.toList();
    print('weights: $weights');

    List smoothedWeights = weights;
    int index = 1;
    while (index <= smoothedWeights.length - 2) {
      int currWeight = smoothedWeights.elementAt(index);
      var currTime = measuredWeights.keys.elementAt(index);

      int nextWeight = smoothedWeights.elementAt(index + 1);
      var nextTime = measuredWeights.keys.elementAt(index + 1);

      if ((currWeight - nextWeight).abs() < 5 ||
          (currTime.inSeconds - nextTime.inSeconds).abs() < 5) {
        smoothedWeights[index + 1] = min(currWeight, nextWeight);
        smoothedWeights.removeAt(index);
      }
      index++;
    }
    print('smoothedWeights: $smoothedWeights');

    List<int> smoothedDiffs = [];
    for (int i = 1; i <= smoothedWeights.length - 1; i++) {
      int weightDifference = smoothedWeights[i - 1] - smoothedWeights[i];
      if (weightDifference > 5) {
        smoothedDiffs.add(weightDifference);
      }
    }
    print('smoothedDiffs: $smoothedDiffs');

    var smoothedBiteAverage =
        smoothedDiffs.reduce((prev, next) => prev + next) ~/
            smoothedDiffs.length;
    print('smoothedBiteAverage: $smoothedBiteAverage');

    return smoothedBiteAverage;
  }

  /// on updates of listened-to provider(s)
  void update(int measuredWeight) {
    addMeasuredWeight(measuredWeight);
    notifyListeners();
  }
}

class RunningUnmeasuredMeal extends RunningMeal {
  late CurveService _curveService;

  static Duration biteBuildupLength = const Duration(seconds: 5);

  Timer? _nextBiteAnimationTimer;
  Timer? _nextBiteTimer;
  late DateTime lastBite;
  late DateTime nextBite;

  RunningUnmeasuredMeal(super.finalMealInfo) {
    _curveService = CurveService(finalMealInfo);

    lastBite = finalMealInfo.startedAt;
    initBiteTimers();
  }

  Duration get timeToNextBite =>
      roundToSeconds(nextBite.difference(DateTime.now()));

  void initBiteTimers() {
    nextBite = finalMealInfo.startedAt.add(getCurrentTimeBetweenBites());
    notifyListeners();

    // TODO reenable
    // startBiteTimers(timeToNextBite);
  }

  void startBiteTimers(Duration timeToNextBite) {
    _nextBiteTimer = Timer(timeToNextBite, updateBiteTimers);
    _nextBiteAnimationTimer =
        Timer((timeToNextBite - biteBuildupLength), updateBiteTimers);
  }

  void updateBiteTimers() {
    Duration oldTimeToNextBite = timeToNextBite;

    // TODO redundant to mealPage
    print('meal_service: '
        'oldTTNB is ${oldTimeToNextBite.inSeconds} s.'
        ' diff to buildup is: ${(oldTimeToNextBite - biteBuildupLength).abs().inSeconds} s.'
        ' this is smaller than 1s:  ${(oldTimeToNextBite - biteBuildupLength).abs() < const Duration(seconds: 2)}');
    if ((oldTimeToNextBite - biteBuildupLength).abs() <
        const Duration(seconds: 1)) {
      //TODO test is fuzzy. refactor timers to something more accurate.
      notifyListeners();
    } else {
      if (oldTimeToNextBite <= Duration.zero) {
        lastBite = DateTime.now();
        Duration newTimeToNextBite = getCurrentTimeBetweenBites();
        nextBite = lastBite.add(newTimeToNextBite);

        startBiteTimers(newTimeToNextBite);
        notifyListeners();

        if (oldTimeToNextBite < Duration.zero) {
          print('warning: overdrawing ttnb by $oldTimeToNextBite seconds');
        }
        //TODO reenable
        // } else {
        //   if (oldTimeToNextBite < biteBuildupLength &&
        //       oldTimeToNextBite > Duration.zero) {
        //     assert(_nextBiteTimer.isActive);
        //     assert(!(_nextBiteAnimationTimer.isActive));
        //   }
      }
    }
  }

  void clearTimers() {
    _nextBiteTimer?.cancel();
    _nextBiteAnimationTimer?.cancel();
  }

  Duration getCurrentTimeBetweenBites() {
    return _curveService.getTimeBetweenBites(timeElapsed);
  }

  @override
  storeMeal() {
    clearTimers();
    var meal = RecordedUnmeasuredMeal(
      finalMealInfo: finalMealInfo,
      endedAt: DateTime.now(),
    );
    StorageService.putMeal(meal);
    return meal;
  }

  @override
  dispose() {
    clearTimers();
    super.dispose();
  }
}

class RunningMeasuredMeal extends RunningMeal {
  late CurveService _curveService;

  Map<Duration, int> _targetWeights = {};

  Map<Duration, int> get targetWeights => _targetWeights;
  Map<Duration, int> _measuredWeights = {};
  Map<Duration, int> get measuredWeights => _measuredWeights;
  Map<Duration, Duration> tstnb = {}; //times to next bite. debug, not recorded

  int? _measuredBiteSize;

  RunningMeasuredMeal(super.finalMealInfo) {
    _curveService = CurveService(finalMealInfo);

    _targetWeights = {
      const Duration(minutes: 0): finalMealInfo.targetMealSize!,
      finalMealInfo.targetMealLength: 0,
    };
    addTargetWeightsForMinutes();
    _measuredWeights = {};
    tstnb = {};
  }

  @override
  storeMeal() {
    var meal = RecordedMeasuredMeal(
        finalMealInfo: finalMealInfo,
        targetWeights: _targetWeights,
        measuredWeights: _measuredWeights,
        measuredBiteSize: _measuredBiteSize,
        endedAt: DateTime.now());
    StorageService.putMeal(meal);
    return meal;
  }

  /// on updates of listened-to provider(s)
  void update(int measuredWeightOnBite) {
    addMeasuredWeight(measuredWeightOnBite);
    notifyListeners();
  }

  addDummyWeights() {
    measuredWeights.addAll(RecordedMeal.dummyMeasuredWeights);
    targetWeights.addAll(RecordedMeal.dummyTargetWeights);
    notifyListeners();
  }

  addTargetWeightsForMinutes() {
    for (int i = finalMealInfo.targetMealLength.inMinutes; i >= 0; i--) {
      Duration minute = Duration(minutes: i);
      int newTargetWeight = _curveService.targetEatenWeigthFromDecMinutes(i)!;
      if (targetWeights.containsKey(minute)) {
        print(
            'At $i Min targetWeight was ${targetWeights[minute]}, is now $newTargetWeight.');
      }
      targetWeights[minute] = newTargetWeight;
    }
    notifyListeners();
  }

  addMeasuredWeight(int value) {
    //TODO shoud timestamp for measured weight be set here?
    var time = timeElapsed;
    measuredWeights[time] = value;
    print('added weight $value at time $time');
    notifyListeners();
  }

  Duration getTimeToNextBite() {
    Duration cachedTimeElapsed = timeElapsed;
    Duration newTtnb = _curveService.getTimeBetweenBites(cachedTimeElapsed);
    tstnb[cachedTimeElapsed] = newTtnb;
    notifyListeners();
    return newTtnb;
  }

  addTstnbForMinutes() {
    for (int i = finalMealInfo.targetMealLength.inMinutes; i > 0; i--) {
      Duration duration = Duration(minutes: i);
      Duration newTtnb = _curveService.getTimeBetweenBites(duration);
      if (tstnb.containsKey(duration)) {
        print(
            'At ${duration.inMinutes} Min ttnb was ${tstnb[duration]!.inSeconds}, is now ${newTtnb.inSeconds}.');
      }
      tstnb[duration] = newTtnb;
      notifyListeners();
    }
  }
}
