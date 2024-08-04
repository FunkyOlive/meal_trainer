import 'dart:async';

import 'package:meal_trainer/datamodels/meal.dart';
import 'package:meal_trainer/logic/meal_service.dart';
import 'package:meal_trainer/ui/page_meals_export.dart';
import 'package:meal_trainer/ui/ui_components.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnmeasuredMealPage extends StatefulWidget {
  const UnmeasuredMealPage({
    this.title = 'Unmeasured Meal',
    required this.finalMealInfo,
    super.key,
  });

  final String title;
  final FinalMealInfo finalMealInfo;

  @override
  State<UnmeasuredMealPage> createState() => _UnmeasuredMealPageState();
}

class _UnmeasuredMealPageState extends State<UnmeasuredMealPage>
    with SingleTickerProviderStateMixin {
  late MealService _mealService;
  late AnimationController pulseAnimationController;

  Timer? animationTimer;

  bool showdebug = false;

  @override
  void didChangeDependencies() {
    _mealService = context.watch<MealService>();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    pulseAnimationController = AnimationController(
        duration: RunningUnmeasuredMeal.biteBuildupLength, vsync: this);
    pulseAnimationController.forward();
  }

  @override
  void dispose() {
    pulseAnimationController.dispose();
    animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? nextTBB;
    String? lastBite;
    String? nextBite;

    if (_mealService.mealStatus == MealStatus.running) {
      startAnimationTimer();
    }

    List<Widget> pageContent;
    switch (_mealService.mealStatus) {
      case MealStatus.prepared:
        pageContent = <Widget>[
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _mealService.toString(),
                textAlign: TextAlign.center,
              )),
          ButtonList(buttons: [
            ElevatedButton(
                child: const Text('Start meal'),
                onPressed: () => _mealService.startMeal(
                      widget.finalMealInfo,
                      RunningUnmeasuredMeal,
                    )),
          ]),
        ];
        break;
      case MealStatus.running:
        pageContent = <Widget>[
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _mealService.toString(),
                textAlign: TextAlign.center,
              )),
          ButtonList(buttons: [
            ElevatedButton(
                child: const Text('Abort meal'),
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
          if (showdebug)
            Column(
              children: [
                Text('last bite at $lastBite seconds elapsed'),
                Text('next bite at $nextBite seconds elapsed'),
                Text('next timeBetweenBites: $nextTBB seconds'),
                ElevatedButton(
                    child: const Text('restart pulse animation'),
                    onPressed: () => {
                          pulseAnimationController
                            ..reset()
                            ..forward()
                        }),
              ],
            ),
          PulseAnimation(pulseAnimationController: pulseAnimationController),
        ];
        break;
      case MealStatus.timeout:
        pageContent = <Widget>[
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _mealService.toString(),
                textAlign: TextAlign.center,
              )),
          ButtonList(buttons: [
            ElevatedButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const ExportPage(
                                exportReason: ExportReason.mealFinished,
                              )),
                      (route) => false);
                }),
          ]),
        ];
        break;
      case MealStatus.overtime:
        throw Exception('called overtime on meal with no measurements');
      case MealStatus.ended:
        throw (Exception('opened MealPage on ended or non-initialized meal'));
    }

    return Scaffold(
        appBar: UIcomponents.getAppBar(context, widget.title),
        drawer: UIcomponents.getDrawer(context),
        body: SingleChildScrollView(
            child: Center(child: Column(children: pageContent))));
  }

  void startAnimationTimer() {
    var tbb = (_mealService.runningMeal as RunningUnmeasuredMeal)
        .getCurrentTimeBetweenBites();
    animationTimer = Timer(tbb, () {
      pulseAnimationController.reset();
      pulseAnimationController.forward();
      startAnimationTimer();
    });
  }
}

class PulseAnimation extends StatefulWidget {
  const PulseAnimation({
    super.key,
    required this.pulseAnimationController,
  });

  final AnimationController pulseAnimationController;

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> {
  late Animation sizeAnimation;
  late Animation colorAnimation;
  late Animation opacityAnimation;
  static const double pulseMaxSize = 180;

  @override
  void initState() {
    colorAnimation = //TODO put in TweenSequence for Anticipation
        ColorTween(begin: Colors.blue[900], end: Colors.lightBlue[200]).animate(
            CurvedAnimation(
                parent: widget.pulseAnimationController,
                curve: const Interval(0.0, 1.0, curve: Curves.ease)));

    sizeAnimation = Tween(begin: 150.0, end: pulseMaxSize).animate(
        CurvedAnimation(
            parent: widget.pulseAnimationController,
            curve: const Interval(0.6, 1.0, curve: Curves.ease)));

    opacityAnimation = Tween(begin: 0.9, end: 0.0).animate(CurvedAnimation(
            parent: widget.pulseAnimationController,
            curve: const Interval(0.7, 1.0, curve: Curves.ease)))
        // ..addStatusListener((status) => print('opacityTween status: $status'))
        ;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.pulseAnimationController,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          height: pulseMaxSize,
          width: pulseMaxSize,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Container(
                width: 150.0,
                height: 150.0,
                decoration: BoxDecoration(
                  color: colorAnimation.value,
                  shape: BoxShape.circle,
                ),
              ),
              Opacity(
                opacity: opacityAnimation.value,
                child: Container(
                  width: sizeAnimation.value,
                  height: sizeAnimation.value,
                  decoration: const BoxDecoration(
                    color: Colors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
