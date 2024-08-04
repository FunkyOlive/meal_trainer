import 'package:hive_flutter/hive_flutter.dart';

import 'package:meal_trainer/datamodels/duration_adapter.dart';
import 'package:meal_trainer/datamodels/meal.dart';

abstract class StorageService {
  static const String _hiveDBName = 'mealBox';

  static Future<void> initDB() async {
    _registerAdapters();
    await Hive.initFlutter();

    await _openBox();
  }

  static void _registerAdapters() {
    Hive.registerAdapter(DurationAdapter());
    Hive.registerAdapter(FinalMealInfoAdapter());
    Hive.registerAdapter(RecordedCalibrationMealAdapter());
    Hive.registerAdapter(RecordedUnmeasuredMealAdapter());
    Hive.registerAdapter(RecordedMeasuredMealAdapter());
  }

  static Future<void> _openBox() async {
    var box = await Hive.openBox(_hiveDBName);
    print('Hive Box opened, it has ${box.values.length} entries.');
  }

  static Future<void> flushDB() async {
    await Hive.deleteFromDisk();
    await _openBox();
  }

  /// Only of [patient] or all; [sorted] by Date, descending
  static Iterable<M> getMeals<M extends RecordedMeal>(
      {bool sorted = false, String? patient}) {
    Iterable<M> mealsOfType = Hive.box(_hiveDBName).values.whereType<M>();
    if (sorted) {
      mealsOfType = mealsOfType.toList()
        ..sort((a, b) =>
            b.finalMealInfo.startedAt.compareTo(a.finalMealInfo.startedAt));
    }

    if (patient != null) {
      return mealsOfType
          .where((meal) => patient == meal.finalMealInfo.eatingPatient);
    } else {
      return mealsOfType;
    }
  }

  static List<String> getPatients({bool sorted = false}) {
    var meals = getMeals(sorted: sorted);
    if (meals.isEmpty) {
      return List.empty();
    }
    var patients = meals.map((meal) => meal.finalMealInfo.eatingPatient);
    return _removeDuplicates(patients).toList();
  }

  /// Get length of newest meal of [patient], or in general if patient is null, or null if no meals are found.
  static Duration? proposeMealLength({String? patient}) {
    var meals = getMeals(patient: patient, sorted: true);
    return (meals.isEmpty) ? null : meals.first.finalMealInfo.targetMealLength;
  }

  /// Get size of newest meal of [patient], or of anyone if patient is null or patient has none in his meals, or null if no meals with sizes are found.
  static int? proposeMealSize({String? patient}) {
    if (patient != null) {
      var patientMeals = getMeals(sorted: true, patient: patient);

      Iterable<RecordedMeal> mealsWithMealSize;
      int? newestMealSizeOfPatient;
      mealsWithMealSize = patientMeals
          .where((meal) => meal.finalMealInfo.targetMealSize != null);
      if (mealsWithMealSize.isEmpty) {
        return null;
      } else {
        newestMealSizeOfPatient =
            mealsWithMealSize.first.finalMealInfo.targetMealSize;
      }
      if (newestMealSizeOfPatient != null) {
        return newestMealSizeOfPatient;
      }
    }
    var allMeals = getMeals(sorted: true, patient: null);
    if (allMeals.isEmpty) {
      return null;
    }
    Iterable<RecordedMeal> mealsWithMealSize =
        allMeals.where((meal) => meal.finalMealInfo.targetMealSize != null);
    if (mealsWithMealSize.isEmpty) {
      return null;
    }
    return mealsWithMealSize.first.finalMealInfo.targetMealSize;
  }

  /// Get the relevant biteSize from past meals of [eatingPatient] for use in starting a new Meal.
  static int? proposeBiteSize({required String patient}) {
    var mealsWithBiteSize =
        getMeals(patient: patient, sorted: true).where((meal) {
      switch (meal.runtimeType) {
        case RecordedCalibrationMeal:
          meal = meal as RecordedCalibrationMeal;
          return (meal.measuredBiteSize != null);
        case RecordedMeasuredMeal:
          meal = meal as RecordedMeasuredMeal;
          return (meal.measuredBiteSize != null);
        default:
          return false;
      }
    });

    var calibrationMealsWithBiteSize =
        mealsWithBiteSize.whereType<RecordedCalibrationMeal>();
    var measuredMealsWithBiteSize =
        mealsWithBiteSize.whereType<RecordedMeasuredMeal>();

    if (calibrationMealsWithBiteSize.isNotEmpty) {
      return calibrationMealsWithBiteSize.first.measuredBiteSize!;
    } else {
      if (measuredMealsWithBiteSize.isNotEmpty) {
        return measuredMealsWithBiteSize.first.measuredBiteSize!;
      } else {
        return null;
      }
    }
  }

  static String? getLastPatient() {
    var meals = getMeals(sorted: true);
    return meals.isEmpty ? null : meals.first.finalMealInfo.eatingPatient;
  }

  static Future<void> putMeal(RecordedMeal recordedMeal) async =>
      await Hive.box(_hiveDBName).add(recordedMeal);

  static Set<T> _removeDuplicates<T>(Iterable<T> duplicates) {
    return duplicates.toSet();
  }
}
