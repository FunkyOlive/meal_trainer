import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/logic/meal_service.dart';
import 'package:meal_trainer/ui/page_meals_export.dart';
import 'package:meal_trainer/ui/scale_card.dart';
import 'package:meal_trainer/ui/ui_components.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalibrationMealPage extends StatefulWidget {
  const CalibrationMealPage({
    this.title = 'Calibration Meal',
    required this.finalMealInfo,
    super.key,
  });

  final FinalMealInfo finalMealInfo;
  final String title;

  @override
  State<CalibrationMealPage> createState() => _CalibrationMealPageState();
}

class _CalibrationMealPageState extends State<CalibrationMealPage> {
  late MealService _mealService;

  late RunningCalibrationMeal _runningCalibrationMeal;

  @override
  void didChangeDependencies() {
    _mealService = context.watch<MealService>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pageContent = [];

    switch (_mealService.mealStatus) {
      case MealStatus.prepared:
        pageContent = [
          SizedBox(
              height: 200,
              width: 400,
              child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all(width: 2)),
                  child: const Text(''))),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _mealService.toString(),
                textAlign: TextAlign.center,
              )),
          const ScaleCard(hasLinkToScaleSetup: true),
          ButtonList(buttons: [
            ElevatedButton(
                child: const Text('Start Meal'),
                onPressed: () => _mealService.startMeal(
                      widget.finalMealInfo,
                      RunningCalibrationMeal,
                    )),
          ]),
        ];
        break;
      case MealStatus.overtime:
      case MealStatus.running:
        _runningCalibrationMeal =
            _mealService.runningMeal as RunningCalibrationMeal;

        pageContent = [
          MealChart(
            mealInfo: _runningCalibrationMeal.finalMealInfo,
            measuredWeights: _runningCalibrationMeal.measuredWeights,
          ),
          Text(_mealService.toString()),
          ButtonList(buttons: [
            ElevatedButton(
                child: const Text('Abort Meal'),
                onPressed: () {
                  _mealService.pauseMeal();
                  Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const ExportPage(
                                exportReason: ExportReason.mealAborted,
                              )));
                }),
          ]),
        ];
        break;
      case MealStatus.timeout:
        pageContent = <Widget>[
          const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Meal has reached meal length.',
                textAlign: TextAlign.center,
              )),
          ButtonList(buttons: [
            OutlinedButton(
                onPressed: () => setState(
                    () => _mealService.mealStatus = MealStatus.overtime),
                child: const Text('Continue meal')),
            ElevatedButton(
                child: const Text('End meal'),
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const ExportPage(
                              exportReason: ExportReason.mealFinished,
                            )),
                    (route) => false)),
          ]),
        ];
        break;
      case MealStatus.ended:
        throw (Exception('opened MealPage on ended or non-initialized meal'));
    }
    return Scaffold(
        appBar: UIcomponents.getAppBar(context, widget.title),
        body: SingleChildScrollView(
            child: Center(child: Column(children: pageContent))));
  }
}
