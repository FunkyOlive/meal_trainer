import 'package:meal_trainer/ui/page_meals_history.dart';
import 'package:meal_trainer/logic/storage_service.dart';
import 'package:meal_trainer/logic/meal_service.dart';
import 'package:meal_trainer/logic/scale_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  await StorageService.initDB();
  //TODO catch async errors and warn with a banner or sth
  runApp(const MealTrainerApp());
}

class MealTrainerApp extends StatelessWidget {
  const MealTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ScaleService()),
          // ChangeNotifierProxyProvider<ScaleService, BiteDetectionService>(
          //     create: (_) => BiteDetectionService(),
          //     update: (_, ScaleService scaleService,
          //         BiteDetectionService? previousService) {
          //       if (previousService == null) {
          //         throw Exception(
          //             'previous BiteService on Measurement update is null');
          //       } else {
          //         return previousService.update(scaleService);
          //       }
          //     }),
          ChangeNotifierProxyProvider<ScaleService, MealService>(
              create: (_) => MealService(),
              update:
                  (_, ScaleService scaleService, MealService? previousService) {
                if (previousService == null) {
                  throw Exception(
                      'previous Mealservice on Measurement update is null');
                } else {
                  int? taredLastWeight = scaleService.taredLastWeight;
                  return taredLastWeight != null
                      ? previousService.update(taredLastWeight)
                      : previousService;
                }
              }),
        ],
        child: MaterialApp(
            title: 'Meal Trainer',
            theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
            home: const MealHistoryPage()));
  }
}
