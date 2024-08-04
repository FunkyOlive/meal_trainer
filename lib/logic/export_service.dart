import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/ui/ui_components.dart';

abstract class ExportService {
  /// exports meals to csv file saved at user-chosen location
  // TODO: ...or via share intent, or dropbox upload
  // TODO on images: export images separately
  static Future<void> exportMeals({
    required Iterable<RecordedMeal> meals,
    String? description,
  }) async {
    final List<List<String>> mealList = convertMealsToLists(meals);
    final csvString = const ListToCsvConverter().convert(mealList);

    FilePicker.platform.saveFile(
        dialogTitle: 'Choose directory for exporting meals',
        fileName: (description != null)
            ? 'meals_${toTimeString(DateTime.now(), exportFormat: true)}_$description.csv'
            : 'meals_${toTimeString(DateTime.now(), exportFormat: true)}.csv',
        allowedExtensions: ['csv'],
        type: FileType.custom,
        bytes: Uint8List.fromList(csvString.codeUnits));
  }

  static List<List<String>> convertMealsToLists(
      Iterable<RecordedMeal> listedMeals) {
    if (listedMeals.isEmpty) {
      throw Exception('tried exporting empty meal list');
    }

    final Iterable<Map<String, String>> maps = listedMeals.map((meal) {
      var map = <String, String>{
        'startedAt': toTimeString(
          meal.finalMealInfo.startedAt,
          exportFormat: true,
        ),
        'endedAt': toTimeString(
          meal.endedAt,
          exportFormat: true,
        ),
        'eatingPatient': meal.finalMealInfo.eatingPatient,
        'targetMealLength':
            meal.finalMealInfo.targetMealLength.inMinutes.toString(),
        'targetMealSize': meal.finalMealInfo.targetMealSize.toString(),
        'targetBiteSize': meal.finalMealInfo.initialBiteSize.toString(),
        'linearFactor': meal.finalMealInfo.linearFactor.toString(),
        'quadraticFactor': meal.finalMealInfo.quadraticFactor.toString(),
      };
      switch (meal.runtimeType) {
        case RecordedUnmeasuredMeal:
          //no further fields to add
          break;
        case RecordedMeasuredMeal:
          meal = (meal as RecordedMeasuredMeal);
          map.addAll(<String, String>{
            'measuredBiteSize': meal.measuredBiteSize.toString(),
            'measuredWeights': meal.measuredWeights
                .map((key, value) => MapEntry(key.inMinutes, value))
                .toString(),
            'targetWeights': meal.targetWeights
                .map((key, value) => MapEntry(key.inMinutes, value))
                .toString(),
          });
          break;
        case RecordedCalibrationMeal:
          meal = (meal as RecordedCalibrationMeal);
          map.addAll(<String, String>{
            'measuredBiteSize': meal.measuredBiteSize.toString(),
            'measuredWeights': meal.measuredWeights
                .map((key, value) => MapEntry(key.inMinutes, value))
                .toString(),
          });
          break;
        default:
          throw (Exception('unknown subtype of RecordedMeal'));
      }
      return map;
    });

    final Iterable<List<String>> lists = maps.map((map) => map.values.toList());
    final List<List<String>> listsWithHeader = [
      maps.first.keys.toList(),
      ...lists
    ];
    return listsWithHeader;
  }
}
