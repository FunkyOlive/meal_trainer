import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/logic/export_service.dart';
import 'package:meal_trainer/logic/meal_service.dart';
import 'package:meal_trainer/logic/storage_service.dart';
import 'package:meal_trainer/ui/page_meals_history.dart';
import 'package:meal_trainer/ui/ui_components.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ExportReason { mealAborted, mealFinished, openedFromMenu }

class ExportPage extends StatefulWidget {
  const ExportPage({
    this.title = 'Meal End', //TODO adjust on MealEndPage
    required this.exportReason,
    super.key,
  });

  final String title;
  final ExportReason exportReason;

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  late MealService _mealService;
  bool confirmMealEnd = true;
  RecordedMeal? lastMeal;

  @override
  void didChangeDependencies() {
    _mealService = context.read<MealService>(); //TODO watch?
    super.didChangeDependencies();
  }

  @override
  void initState() {
    switch (widget.exportReason) {
      case ExportReason.mealAborted:
        confirmMealEnd = true;
        break;
      case ExportReason.mealFinished:
        confirmMealEnd = false;
        break;
      case ExportReason.openedFromMenu:
        confirmMealEnd = false;
        break;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exportReason == ExportReason.mealFinished) {
      lastMeal = _mealService.endMeal();
    }

    var meals = StorageService.getMeals();
    if (meals.isNotEmpty) {
      lastMeal ??= meals.first;
    }
    return Scaffold(
        appBar: UIcomponents.getAppBar(context, widget.title),
        drawer: confirmMealEnd ? null : UIcomponents.getDrawer(context),
        body: SingleChildScrollView(
            child: Center(
                child: confirmMealEnd
                    ? Column(children: <Widget>[
                        const Text('Do you really want to abort the meal?'),
                        ButtonList(buttons: [
                          OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(context, 'aborted'),
                              child: const Text('Return to meal')),
                          ElevatedButton(
                              onPressed: () {
                                try {
                                  var currentRoute = ModalRoute.of(context)!;
                                  Navigator.removeRouteBelow(
                                      context, currentRoute);
                                } catch (e) {
                                  print(e);
                                }
                                lastMeal = _mealService.endMeal();

                                setState(() => confirmMealEnd = false);
                              },
                              child: const Text('End meal'))
                        ])
                      ])
                    : Column(children: <Widget>[
                        if (widget.exportReason != ExportReason.openedFromMenu)
                          Column(children: [
                            Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text('Meal finished!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge)),
                            // TODO abstract this together with mealHistory
                            if (lastMeal is RecordedCalibrationMeal)
                              Text(
                                  ((lastMeal as RecordedCalibrationMeal)
                                              .measuredBiteSize ==
                                          null)
                                      ? 'Bite size: no result'
                                      : 'Bite size: ${(lastMeal as RecordedCalibrationMeal).measuredBiteSize} g',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            if (lastMeal is RecordedMeasuredMeal)
                              Text(
                                  'Measurements: '
                                  '${(lastMeal as RecordedMeasuredMeal).measuredWeights.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            if (lastMeal is RecordedUnmeasuredMeal)
                              Text(
                                  'Training effect: '
                                  'achieved',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            const Text(
                                'Meal data has been saved.\nDo you want to export it?'),
                          ]),
                        ButtonList(buttons: [
                          if (widget.exportReason !=
                              ExportReason.openedFromMenu)
                            ElevatedButton(
                                onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const MealHistoryPage())),
                                child: const Text('Close')),
                          OutlinedButton(
                              onPressed: () =>
                                  ExportService.exportMeals(meals: [lastMeal!]),
                              child: const Text('Last meal only')),
                          OutlinedButton(
                              onPressed: () => ExportService.exportMeals(
                                  meals: StorageService.getMeals(
                                      patient: lastMeal!
                                          .finalMealInfo.eatingPatient)),
                              child: Text(
                                  'All meals of patient "${lastMeal!.finalMealInfo.eatingPatient}"')),
                          OutlinedButton(
                              onPressed: () => ExportService.exportMeals(
                                  meals: StorageService.getMeals()),
                              child: const Text('All meals')),
                        ]),
                      ]))));
  }
}
