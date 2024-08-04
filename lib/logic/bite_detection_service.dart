import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:meal_trainer/logic/scale_service.dart';

/// notifies of dummy new weight (linear curve) every 3 seconds until default meal ends
class DummyBiteDetectionService extends BiteDetectionService {
  //TODO get from config
  final int mealWeight = 350;
  final int mealLengthSeconds = 14 * 60;
  int secondsElapsed = 0;

  DummyBiteDetectionService() : super() {
    dummyBiteRecursion(secondsDelay: 14);
  }

  dummyBiteRecursion({required int secondsDelay}) {
    if (secondsElapsed > mealLengthSeconds) return;

    Future.delayed(Duration(seconds: secondsDelay)).then((_) {
      secondsElapsed += secondsDelay;
      dummyBite(mealWeight * secondsElapsed ~/ mealLengthSeconds);
      dummyBiteRecursion(secondsDelay: secondsDelay);
    });
  }

  void dummyBite(int weight) {
    value = weight;
    print('dummyBite is now $weight');
  }

  /// return (when not dummy: 'updated') self on updates of listened-to provider(s)
  @override
  DummyBiteDetectionService update(_) {
    print('called biteService.update()');
    return this;
  }
}

/// stores weight. When bite occurs this notifies of new weight.
// TODO store timestamp as well? continue using weight as id?
class BiteDetectionService extends ValueNotifier<int> {
  final Queue _weights = Queue();

  //TODO leave on init value -1?
  BiteDetectionService() : super(-1);

  /// return updated self on change of listened-to provider(s)
  BiteDetectionService update(ScaleService scaleService) {
    print('called biteService.update()');

    //TODO is checking SCS here too sensitive to timing? necessary at all?
    if (scaleService.connectionState == ScaleConnectionState.connected &&
        scaleService.taredLastWeight != null) {
      int newWeight = scaleService.taredLastWeight!;
      addToWeightsQueue(newWeight);

      if (checkBiteOccurence(newWeight)) {
        value = newWeight;
      }
    }

    return this;
  }

  void addToWeightsQueue(int lastMeasurement) {
    //TODO require keeping timeframe of a few secs
    if (_weights.length >= 20) {
      _weights.removeFirst();
    }
    _weights.add(lastMeasurement);
  }

  /// Whether weight diverges sufficiently from the average of past weights
  bool checkBiteOccurence(int lastMeasurement) {
    int weightsAverage =
        (_weights.reduce((value, element) => value + element) ~/
            _weights.length);

    int difference = weightsAverage - lastMeasurement;
    if (difference < -15) {
      print('weight difference is negative by $difference');
    }
    return difference >= 15;
  }
}
