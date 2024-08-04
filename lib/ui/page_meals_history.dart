import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/logic/storage_service.dart';
import 'package:meal_trainer/ui/page_meals_export.dart';
import 'package:meal_trainer/ui/page_meals_new.dart';
import 'package:meal_trainer/ui/ui_components.dart';

import 'package:flutter/material.dart';

class MealHistoryPage extends StatefulWidget {
  const MealHistoryPage({this.title = 'Meal History', super.key});

  final String title;

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

class _MealHistoryPageState extends State<MealHistoryPage> {
  String? _patient;
  late Iterable<RecordedMeal> _listedMeals;

  int _selectedMealIndex = 0;
  RecordedMeal? selectedMeal;

  @override
  void initState() {
    _patient = StorageService.getLastPatient();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _listedMeals = StorageService.getMeals(
      patient: _patient,
      sorted: true,
    );
    if (_listedMeals.isNotEmpty) {
      selectedMeal = _listedMeals.elementAt(_selectedMealIndex);
    }

    Iterable<String> allPatients = StorageService.getPatients(sorted: true);

    return Scaffold(
        appBar: UIcomponents.getAppBar(context, widget.title),
        drawer: UIcomponents.getDrawer(context),
        floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) =>
                        NewMealsPage(lastSelectedPatient: _patient))),
            tooltip: 'Prepare New Meal',
            child: const Icon(Icons.add)),
        body: Center(
            child: _listedMeals.isEmpty
                ? const Text('No saved meals')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        MealChart(
                            mealInfo: selectedMeal!.finalMealInfo,
                            measuredWeights:
                                (selectedMeal is RecordedCalibrationMeal)
                                    ? (selectedMeal as RecordedCalibrationMeal)
                                        .measuredWeights
                                    : (selectedMeal is RecordedMeasuredMeal)
                                        ? (selectedMeal as RecordedMeasuredMeal)
                                            .measuredWeights
                                        : null,
                            targetWeights:
                                (selectedMeal is RecordedMeasuredMeal)
                                    ? (selectedMeal as RecordedMeasuredMeal)
                                        .targetWeights
                                    : null),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (allPatients.length > 1)
                                    DropdownMenu<String>(
                                        label: const Text('select patient'),
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                        dropdownMenuEntries: allPatients
                                            .map((patient) => DropdownMenuEntry(
                                                value: patient, label: patient))
                                            .toList(),
                                        initialSelection: _patient,
                                        onSelected: (String? selectedPatient) {
                                          if (selectedPatient != null &&
                                              selectedPatient != '' &&
                                              _patient != selectedPatient) {
                                            setState(() {
                                              _patient = selectedPatient;
                                              _selectedMealIndex = 0;
                                            });
                                          }
                                        }),
                                  Text('${_listedMeals.length} Meal(s)'),
                                ])),
                        if (allPatients.length > 1) const Divider(),
                        Expanded(
                            child: ListView.builder(
                                itemCount: _listedMeals.length,
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                prototypeItem: const ListTile(
                                  title: Text('Unmeasured Meal'),
                                  subtitle: Text('01.01.1990 at 00:00:00'),
                                  trailing: Text('12345 Measurements'),
                                  contentPadding: EdgeInsets.all(16),
                                ),
                                itemBuilder: (context, index) {
                                  DateTime startedAt = _listedMeals
                                      .elementAt(index)
                                      .finalMealInfo
                                      .startedAt;

                                  Color? color;
                                  if (index == _selectedMealIndex) {
                                    color = const Color.fromARGB(
                                        255, 173, 173, 173);
                                  }

                                  Duration mealDuration = _listedMeals
                                      .elementAt(index)
                                      .endedAt
                                      .difference(_listedMeals
                                          .elementAt(index)
                                          .finalMealInfo
                                          .startedAt);

                                  String titleText, trailingText;
                                  switch (_listedMeals
                                      .elementAt(index)
                                      .runtimeType) {
                                    case RecordedCalibrationMeal:
                                      titleText = 'Measured Bite Size';
                                      trailingText = 'Bitesize: '
                                          '${(_listedMeals.elementAt(index) as RecordedCalibrationMeal).measuredBiteSize}';
                                      break;
                                    case RecordedMeasuredMeal:
                                      titleText = 'Measured Meal';
                                      trailingText = 'Measurements: '
                                          '${(_listedMeals.elementAt(index) as RecordedMeasuredMeal).measuredWeights.length}';
                                      break;
                                    case RecordedUnmeasuredMeal:
                                      titleText = 'Unmeasured Meal';
                                      trailingText = 'Training effect: '
                                          'achieved';
                                      break;
                                    default:
                                      titleText = '-';
                                      trailingText = '-';
                                      throw Exception(
                                          'Unknown subtype of RecordedMeal');
                                  }

                                  Widget tileTrailingWidget = Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(trailingText),
                                        Text('Duration: '
                                            '${mealDuration.inSeconds}'
                                            ' Seconds')
                                      ]);

                                  return InkWell(
                                      onTap: () => setState(() {
                                            _selectedMealIndex = index;
                                          }),
                                      child: ListTile(
                                        title: Text(titleText),
                                        subtitle: Text(toTimeString(startedAt)),
                                        trailing: tileTrailingWidget,
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        tileColor: color,
                                      ));
                                })),
                        const Divider(),
                        ButtonList(buttons: [
                          OutlinedButton(
                              onPressed: _listedMeals.isEmpty
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (_) => const ExportPage(
                                              title: 'Export Meal Data',
                                              exportReason: ExportReason
                                                  .openedFromMenu))),
                              child: const Text('Export Meals')),
                        ]),
                      ])));
  }
}
