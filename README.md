# meal_trainer

 This App along with a scale forms a treatment method for nonintuitive eating behavior connected with multiple eating disorders.
 Original approach: https://mando.se/en/
 Previous prototype (core): https://github.com/d4l-w4r/MealTrainer-Core

## Code Generation
This project uses build_runner to generate Type Adapters used by HiveDB. Whenever classes with Hive annotations (so far only in meal.dart) are changed, before committing rerun build_runner with command `dart run build_runner build` to apply the changes. Keep in mind that they might render DB entries created before unreadable.