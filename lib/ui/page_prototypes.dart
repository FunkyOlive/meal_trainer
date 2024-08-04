import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/logic/curve_service.dart';
import 'package:meal_trainer/logic/storage_service.dart';
import 'package:meal_trainer/ui/page_meals_history.dart';
import 'package:meal_trainer/ui/ui_components.dart';

import 'package:flutter/material.dart';

class PrototypesPage extends StatefulWidget {
  const PrototypesPage({super.key, this.title = 'Prototypes Page'});

  final String title;

  @override
  State<PrototypesPage> createState() => _PrototypesPageState();
}

class _PrototypesPageState extends State<PrototypesPage> {
  final _formKey = GlobalKey<FormState>();
  int _targetMealSize = 350;
  Duration _targetMealLength = const Duration(minutes: 14);
  int _biteSize = 15;

  late FinalMealInfo _finalMealInfo;

  late Map<Duration, int> _targetWeights;

  @override
  void initState() {
    _targetWeights = {Duration.zero: _targetMealSize, _targetMealLength: 0};
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _finalMealInfo = FinalMealInfo(
      eatingPatient: 'Example Patient',
      targetMealLength: _targetMealLength,
      targetMealSize: _targetMealSize,
      initialBiteSize: _biteSize,
    );

    return Scaffold(
        appBar: UIcomponents.getAppBar(
          context,
          widget.title,
        ),
        drawer: UIcomponents.getDrawer(context),
        body: SingleChildScrollView(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    // Invoke "debug painting" (press "p" in the console, choose the
                    // "Toggle Debug Paint" action from the Flutter Inspector in Android
                    // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
                    // to see the wireframe for each widget
                    children: <Widget>[
              Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            initialValue: _targetMealSize.toString(),
                            validator: (value) =>
                                (int.tryParse(value ?? '') == null)
                                    ? 'could not parse'
                                    : null,
                            onSaved: (newValue) =>
                                _targetMealSize = int.parse(newValue!),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text('target meal size (grams)')),
                          )),
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                              initialValue:
                                  _targetMealLength.inMinutes.toString(),
                              validator: (value) =>
                                  (int.tryParse(value ?? '') == null)
                                      ? 'could not parse'
                                      : null,
                              onSaved: (newValue) => _targetMealLength =
                                  Duration(minutes: int.parse(newValue!)),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label:
                                      Text('target meal length (minutes)')))),
                      ButtonList(buttons: [
                        ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _formKey.currentState!.save();
                                });
                              }
                            },
                            child: const Text('update chart')),
                        OutlinedButton(
                            onPressed: () {
                              final legacyCurveService = LegacyCurveService(
                                  targetMealLength: _targetMealLength,
                                  targetMealSize: _targetMealSize,
                                  initialBiteSize: _biteSize);
                              Map<Duration, int> newTargetWeights = {};
                              for (int i = _targetMealLength.inMinutes;
                                  i >= 0;
                                  i--) {
                                final newTargetEatenWeight = legacyCurveService
                                    .targetEatenWeightFromDecMinutes(
                                        i.toDouble())
                                    .round();
                                final newTargetWeight =
                                    _targetMealSize - newTargetEatenWeight;
                                newTargetWeights[Duration(minutes: i)] =
                                    newTargetWeight;
                              }
                              print(newTargetWeights.map((key, value) =>
                                  MapEntry(key.inMinutes, value)));
                              setState(
                                () => _targetWeights = newTargetWeights,
                              );
                            },
                            child: const Text('update target weights'))
                      ]),
                    ],
                  )),
              const Text('Meal Chart'),
              MealChart(
                measuredWeights: null,
                targetWeights: _targetWeights,
                mealInfo: _finalMealInfo,
              ),
              const Divider(),
              ButtonList(buttons: [
                OutlinedButton(
                    child: const Text('flush database'),
                    onPressed: () async => await StorageService.flushDB()),
                ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MealHistoryPage())),
                    child: const Text('open Home Screen'))
              ]),
            ]))));
  }
}
