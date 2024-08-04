import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/ui/page_meals_export.dart';
import 'package:meal_trainer/ui/scale_card.dart';
import 'package:meal_trainer/ui/ui_components.dart';
import 'package:meal_trainer/logic/meal_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MeasuredMealPage extends StatefulWidget {
  const MeasuredMealPage({
    this.title = 'Measured Meal',
    required this.finalMealInfo,
    super.key,
  });

  final String title;
  final FinalMealInfo finalMealInfo;

  @override
  State<MeasuredMealPage> createState() => _MeasuredMealPageState();
}

class _MeasuredMealPageState extends State<MeasuredMealPage> {
  late MealService _mealService;
  RunningMeasuredMeal? _runningMeasuredMeal;

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
                      RunningMeasuredMeal,
                    )),
          ]),
        ];
        break;
      case MealStatus.running:
      case MealStatus.overtime:
        _runningMeasuredMeal = _mealService.runningMeal as RunningMeasuredMeal;

        pageContent = [
          MealChart(
              mealInfo: _runningMeasuredMeal!.finalMealInfo,
              measuredWeights: _runningMeasuredMeal!.measuredWeights,
              targetWeights: _runningMeasuredMeal!.targetWeights,
              tstnb: _runningMeasuredMeal!.tstnb),
          Text(_mealService.toString()),
          ButtonList(
            buttons: [
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
              // OutlinedButton(
              //     child: const Text('add dummy weights'),
              //     onPressed: () => _runningMeasuredMeal!.addDummyWeights()),
              // OutlinedButton(
              //     child: const Text('add all target weights'),
              //     onPressed: () =>
              //         _runningMeasuredMeal!.addTargetWeightsForMinutes()),
              // OutlinedButton(
              //     child: const Text('add all times to next bite'),
              //     onPressed: () => _runningMeasuredMeal!.addTstnbForMinutes()),
            ],
          ),
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
