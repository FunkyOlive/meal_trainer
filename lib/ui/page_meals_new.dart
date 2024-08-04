import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/logic/meal_service.dart';
import 'package:meal_trainer/logic/scale_service.dart';
import 'package:meal_trainer/logic/storage_service.dart';
import 'package:meal_trainer/ui/page_meal_calibration.dart';
import 'package:meal_trainer/ui/page_meal_measured.dart';
import 'package:meal_trainer/ui/page_meal_unmeasured.dart';
import 'package:meal_trainer/ui/scale_card.dart';
import 'package:meal_trainer/ui/ui_components.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _MealTypeForForm {
  unmeasuredMeal,
  measuredMeal,
  calibrationMeal;

  @override
  String toString() {
    switch (name) {
      case 'unmeasuredMeal':
        return 'Unmeasured Meal';

      case 'measuredMeal':
        return 'Measured Meal';
      case 'calibrationMeal':
        return 'Measure bite size';
      default:
        throw Exception('MealTypeForForm value not implemented');
    }
  }
}

class NewMealsPage extends StatefulWidget {
  const NewMealsPage({
    this.lastSelectedPatient,
    this.title = 'Prepare New Meal',
    super.key,
  });

  final String? lastSelectedPatient;
  final String title;

  @override
  State<NewMealsPage> createState() => _NewMealsPageState();
}

class _NewMealsPageState extends State<NewMealsPage> {
  late MealService _mealService;

  final _patientFormFieldKey = GlobalKey<FormFieldState>();
  final _mealTypeFormFieldKey = GlobalKey<FormFieldState>();
  final _scaleStatusFormFieldKey = GlobalKey<FormFieldState>();
  final _mealLengthFormFieldKey = GlobalKey<FormFieldState>();
  final _mealSizeFormFieldKey = GlobalKey<FormFieldState>();
  final _biteSizeFormFieldKey = GlobalKey<FormFieldState>();

  late bool addingNewPatient = false;
  String? _patient;

  //if (StorageService.proposeBiteSize(patient: patient))
  _MealTypeForForm _mealType = _MealTypeForForm.calibrationMeal;

  Duration? _mealLength;
  int? _mealSize;
  int? _biteSize;
  final _mealLengthTextController = TextEditingController(),
      _mealSizeTextController = TextEditingController(),
      _biteSizeTextController = TextEditingController();

  @override
  dispose() {
    _mealLengthTextController.dispose();
    _mealSizeTextController.dispose();
    _biteSizeTextController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _mealService = context.read<MealService>();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    _patient = widget.lastSelectedPatient ?? StorageService.getLastPatient();

    if (_patient != null) {
      _mealType = _MealTypeForForm.unmeasuredMeal;
    }
    fillFieldsIfDefault(_mealType);

    super.initState();
  }

  /// update fields (and field display) to default values if containing default values or nothing.
  /// Does not trigger a rebuild (no setState).
  void fillFieldsIfDefault(_MealTypeForForm mealType) {
    // TODO put into logic
    var biteSizeFromPastMeals = (_patient == null)
        ? null
        : StorageService.proposeBiteSize(patient: _patient!);

    // save non-default user inputs
    var oldUserMealLength = (_mealLength == null ||
            _mealLength!.inMinutes <= 1 ||
            _mealLength!.inMinutes == 14)
        ? null
        : _mealLength;
    var oldUserMealSize =
        (_mealSize == 350 || _mealSize == null) ? null : _mealSize;
    var oldUserBiteSize =
        (_biteSize == biteSizeFromPastMeals) ? null : _biteSize;

    // set to defaults
    switch (mealType) {
      case _MealTypeForForm.unmeasuredMeal:
        _mealLength = const Duration(minutes: 14);
        _mealSize = 350;
        _biteSize = biteSizeFromPastMeals;

        break;
      case _MealTypeForForm.measuredMeal:
        _mealLength = const Duration(minutes: 14);
        _mealSize = 350;
        _biteSize = biteSizeFromPastMeals;
        break;
      case _MealTypeForForm.calibrationMeal:
        //fields will be not shown and ignored
        break;
    }

    // overwrite with user input if non-zero
    _mealLength = oldUserMealLength ?? _mealLength;
    _mealSize = oldUserMealSize ?? _mealSize;
    _biteSize = oldUserBiteSize ?? _biteSize;

    // update text fields
    _mealLengthTextController.text = _mealLength?.inMinutes.toString() ?? '';
    _mealSizeTextController.text = _mealSize?.toString() ?? '';
    _biteSizeTextController.text = _biteSize?.toString() ?? '';
  }

  List<bool> getToggleButtonSelectionArray(_MealTypeForForm mealType) =>
      [false, false, false]..[mealType.index] = true;

  @override
  Widget build(BuildContext context) {
    Iterable<String> allPatients = StorageService.getPatients(sorted: true);

    bool needNewPatient = false;
    if (allPatients.isEmpty) {
      addingNewPatient = true;
      needNewPatient = true;
    }

    return Scaffold(
        appBar: UIcomponents.getAppBar(context, widget.title),
        drawer: UIcomponents.getDrawer(context),
        body: SingleChildScrollView(
            child: Center(
                child: Form(
                    child: Column(children: <Widget>[
          Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FormField<String>(
                        key: _patientFormFieldKey,
                        initialValue: _patient,
                        builder: (FormFieldState<String> formFieldState) =>
                            Expanded(
                                child: !addingNewPatient
                                    ? DropdownMenu<String>(
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
                                              selectedPatient != '') {
                                            setState(() {
                                              _patient = selectedPatient;
                                              fillFieldsIfDefault(_mealType);
                                            });
                                          }
                                        })
                                    : TextField(
                                        decoration: InputDecoration(
                                            label: const Text('new patient'),
                                            border: const OutlineInputBorder(),
                                            errorText:
                                                formFieldState.errorText),
                                        onSubmitted: (newPatient) {
                                          if (_patientFormFieldKey.currentState!
                                              .validate()) {
                                            setState(() {
                                              _patient = newPatient;
                                              fillFieldsIfDefault(_mealType);
                                            });
                                          }
                                        })),
                        validator: (String? value) {
                          return value == null ||
                                  value.length < 3 ||
                                  value.length > 25 ||
                                  !(value.codeUnits.every((char) =>
                                      (char >= 48 && char <= 57) ||
                                      (char >= 65 && char <= 90) ||
                                      (char >= 97 && char <= 122) ||
                                      char == 228 ||
                                      char == 246 ||
                                      char == 252 ||
                                      char == 32))
                              ? 'Please enter between 3 and 25 Numbers or Letters'
                              : null;
                        }),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: needNewPatient
                          ? null
                          : IconButton.filled(
                              tooltip: addingNewPatient
                                  ? 'select patient'
                                  : 'add new patient',
                              icon: addingNewPatient
                                  ? const Icon(Icons.switch_account)
                                  : const Icon(Icons.add),
                              onPressed: () => setState(
                                  () => addingNewPatient = !addingNewPatient)),
                    ),
                  ])),

          //since this is only indirect user input a field here is just a hacky way to get errorText.
          FormField<void>(
              key: _scaleStatusFormFieldKey,
              builder: (field) => Column(
                    children: [
                      const ScaleCard(hasLinkToScaleSetup: true),
                      if (field.hasError)
                        Text(field.errorText!,
                            style: const TextStyle(color: Colors.red)),
                    ],
                  ),
              validator: (_) {
                return (context.read<ScaleService>().connectionState !=
                        ScaleConnectionState.connected)
                    ? 'Please connect the scale.'
                    : null;
              }),

          Container(
              padding: const EdgeInsets.all(12),
              child: FormField<_MealTypeForForm>(
                  key: _mealTypeFormFieldKey,
                  builder: (formFieldState) => ToggleButtons(
                      borderRadius: BorderRadius.circular(4),
                      isSelected: getToggleButtonSelectionArray(_mealType),
                      children: _MealTypeForForm.values
                          .map((mealtype) => Container(
                              padding: const EdgeInsets.all(12),
                              child: Text(mealtype.toString())))
                          .toList(),
                      onPressed: (newIndex) => setState(() {
                            _mealType = _MealTypeForForm.values[newIndex];
                            fillFieldsIfDefault(_mealType);
                          })))),

          if (_mealType != _MealTypeForForm.calibrationMeal)
            Column(
              children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      key: _mealLengthFormFieldKey,
                      controller: _mealLengthTextController,
                      decoration: const InputDecoration(
                          label: Text('target meal Length (minutes)'),
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      // //TODO onSubmitted / onChanged overwrite field (and not set state and not fillFieldsIfDefault())
                      // validator: (String? valueString) {
                      //   int? value = int.tryParse(valueString ?? '');
                      //   return (value == null || value < 1 || value > 300)
                      //       ? 'please enter a Number between 1 and 300 without special characters'
                      //       : null;
                      // },
                    )),
                Container(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      key: _mealSizeFormFieldKey,
                      controller: _mealSizeTextController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          label: Text('target meal size (gram)'),
                          border: OutlineInputBorder()),
                      // //TODO onSubmitted / onChanged overwrite field (and not set state and not fillFieldsIfDefault())
                      // validator: (String? valueString) {
                      //   int? value = int.tryParse(valueString ?? '');
                      //   return (value == null || value < 1 || value > 5000)
                      //       ? 'please enter a Number between 1 and 5000 without special characters'
                      //       : null;
                      // },
                    )),
                Container(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      key: _biteSizeFormFieldKey,
                      controller: _biteSizeTextController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          label: Text('patient bite size (gram)'),
                          border: OutlineInputBorder()),
                      onFieldSubmitted: (String? newValue) {
                        if (_biteSizeFormFieldKey.currentState!.validate()) {
                          _biteSize = int.parse(newValue!);
                        }
                      },
                      validator: (String? newValue) {
                        int? value = int.tryParse(newValue ?? '');
                        return (value == null || value < 5 || value > 200)
                            ? 'Please enter a Number between 5 and 200 without special characters'
                            : null;
                      },
                    )),
              ],
            ),

          // Photo

          ButtonList(buttons: [
            ElevatedButton(
                onPressed: () {
                  if (validate(_mealType)) {
                    _mealService.mealStatus = MealStatus.prepared;

                    switch (_mealType) {
                      case _MealTypeForForm.unmeasuredMeal:
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => UnmeasuredMealPage(
                                        finalMealInfo: FinalMealInfo(
                                      eatingPatient: _patient!,
                                      targetMealLength: _mealLength!,
                                      targetMealSize: _mealSize,
                                      initialBiteSize: _biteSize,
                                    ))),
                            (_) => false);
                        break;
                      case _MealTypeForForm.measuredMeal:
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => MeasuredMealPage(
                                        finalMealInfo: FinalMealInfo(
                                      eatingPatient: _patient!,
                                      targetMealLength: _mealLength!,
                                      targetMealSize: _mealSize,
                                      initialBiteSize: _biteSize,
                                    ))),
                            (_) => false);
                        break;
                      case _MealTypeForForm.calibrationMeal:
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => CalibrationMealPage(
                                        finalMealInfo: FinalMealInfo(
                                      eatingPatient: _patient!,
                                      targetMealLength:
                                          const Duration(minutes: 1),
                                    ))),
                            (_) => false);
                        break;
                    }
                  }
                },
                child: const Text('Prepare Meal')),
          ]),
        ])))));
  }

  bool validate(_MealTypeForForm mealType) {
    switch (mealType) {
      case _MealTypeForForm.unmeasuredMeal:
        return _patientFormFieldKey.currentState!.validate() &&
            _mealLengthFormFieldKey.currentState!.validate() &&
            _mealSizeFormFieldKey.currentState!.validate() &&
            _biteSizeFormFieldKey.currentState!.validate();

      case _MealTypeForForm.measuredMeal:
        return _patientFormFieldKey.currentState!.validate() &&
            _mealLengthFormFieldKey.currentState!.validate() &&
            _mealSizeFormFieldKey.currentState!.validate() &&
            _biteSizeFormFieldKey.currentState!.validate() &&
            _scaleStatusFormFieldKey.currentState!.validate();

      case _MealTypeForForm.calibrationMeal:
        return _patientFormFieldKey.currentState!.validate() &&
            _scaleStatusFormFieldKey.currentState!.validate();
    }
  }
}
