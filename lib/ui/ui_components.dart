import 'package:meal_trainer/datamodels/meal.dart';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

String toTimeString(DateTime time, {bool exportFormat = false}) {
  return exportFormat
      ? '${time.year.toString().padLeft(4, '0')}'
          '-${time.month.toString().padLeft(2, '0')}'
          '-${time.day.toString().padLeft(2, '0')}'
          '_${time.hour.toString().padLeft(2, '0')}'
          ':${time.minute.toString().padLeft(2, '0')}'
      : '${time.day.toString().padLeft(2, '0')}'
          '.${time.month.toString().padLeft(2, '0')}'
          '.${time.year.toString().padLeft(4, '0')}'
          ' at ${time.hour.toString().padLeft(2, '0')}'
          ':${time.minute.toString().padLeft(2, '0')}'
          ':${time.second.toString().padLeft(2, '0')}';
}

abstract class UIcomponents {
  //TODO make factory or move into classes?!
  static getAppBar(BuildContext context, String title) {
    //TODO control navButton
    //switch (navButtonType) { AppBar.leading = ...}

    return AppBar(
      title: Text(title),
    );
  }

  static getDrawer(BuildContext context) {
    return null;
    // return Drawer(
    //     child: ListView(padding: EdgeInsets.zero, children: [
    //   // DrawerHeader(
    //   //     decoration: const BoxDecoration(color: Colors.orange),
    //   //     child: Column(children: [
    //   //       Row(children: [
    //   //         const Text('Patient Nr. 42'),
    //   //         IconButton(
    //   //             onPressed: () => {
    //   //                   Navigator.push(context, MaterialPageRoute<void>(
    //   //                     builder: (BuildContext context) {
    //   //                       return const ChangeUserPage();
    //   //                     },
    //   //                   ))
    //   //                 },
    //   //             icon: const Icon(Icons.account_circle)),
    //   //       ]),
    //   //     ])),
    //   // ListTile(
    //   //     title: const Text('Prototypes Page'),
    //   //     onTap: () {
    //   //       Navigator.push(context,
    //   //           MaterialPageRoute<void>(builder: (BuildContext context) {
    //   //         return const PrototypesPage();
    //   //       }));
    //   //     }),
    //   ListTile(
    //       title: const Text('Meal History Page'),
    //       onTap: () {
    //         Navigator.push(context,
    //             MaterialPageRoute<void>(builder: (BuildContext context) {
    //           return const MealHistoryPage();
    //         }));
    //       }),
    //   ListTile(
    //       title: const Text('New Meal Page'),
    //       onTap: () {
    //         Navigator.push(context,
    //             MaterialPageRoute<void>(builder: (BuildContext context) {
    //           return const NewMealsPage();
    //         }));
    //       }),
    //   ListTile(
    //       title: const Text('Scale Setup Page'),
    //       onTap: () {
    //         Navigator.push(context,
    //             MaterialPageRoute<void>(builder: (BuildContext context) {
    //           return const ScaleSetupPage();
    //         }));
    //       }),
    //   ListTile(
    //       title: const Text('Export Page'),
    //       onTap: () {
    //         Navigator.push(context,
    //             MaterialPageRoute<void>(builder: (BuildContext context) {
    //           return const ExportPage(
    //               exportReason: ExportReason.openedFromMenu);
    //         }));
    //       }),
    // ]));
  }
}

class ButtonList extends StatelessWidget {
  late final List<Padding> _boxedButtonsPaddings;

  ButtonList({super.key, required List<ButtonStyleButton> buttons}) {
    List<Padding> boxes = [];
    for (var button in buttons) {
      boxes.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: SizedBox(
          height: 64,
          width: double.infinity,
          child: button,
          //TODO Style: Font
        ),
      ));
    }
    _boxedButtonsPaddings = boxes;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _boxedButtonsPaddings,
      ),
    );
  }
}

class MealChart extends StatelessWidget {
  final FinalMealInfo mealInfo;
  late final List<LineChartBarData> lineBarsData;

  MealChart(
      {required this.mealInfo,
      final Map<Duration, int>? targetWeights, // TODO set required
      final Map<Duration, int>? measuredWeights,
      final Map<Duration, Duration>? tstnb,
      super.key}) {
    lineBarsData = [];

    [measuredWeights, targetWeights]
      ..removeWhere((map) => (map == null || map.isEmpty))
      ..forEach((map) {
        //TODO Farbe in Legende
        Color barColor;
        switch (lineBarsData.length) {
          case 0:
            barColor = Colors.deepPurple;
            break;
          case 1:
            barColor = Colors.lightGreen;
            break;
          default:
            throw Exception('no color assigned for chart bar');
        }
        List<FlSpot> spots = convertWeightsToSpots(map!);
        sortSpots(spots);

        lineBarsData.add(LineChartBarData(color: barColor, spots: spots));
      });

    // debug
    if (tstnb != null && tstnb.isNotEmpty) {
      List<FlSpot> tstnbSpots = tstnb.entries.map((ttnb) {
        return FlSpot(
            ttnb.key.inSeconds.toDouble(), ttnb.value.inSeconds.toDouble());
      }).toList();
      sortSpots(tstnbSpots);
      lineBarsData
          .add(LineChartBarData(color: Colors.deepOrange, spots: tstnbSpots));
    }
  }

  void sortSpots(List<FlSpot> spots) {
    spots.sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> convertWeightsToSpots(Map<Duration, int> weights) {
    return weights.entries.map((weight) {
      return FlSpot(weight.key.inSeconds.toDouble(), weight.value.toDouble());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 2,
        child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 18,
              top: 10,
              bottom: 4,
            ),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    List<LineTooltipItem> items = [];
                    for (var spot in touchedSpots) {
                      String text;
                      (spot.barIndex == 2)
                          ? text = '${spot.y.round()}s'
                          : text = '${spot.y.round()}g';
                      items.add(LineTooltipItem(text,
                          TextStyle(fontSize: 18, color: spot.bar.color)));
                    }
                    return items;
                  },
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (touchedSpot) => Colors.grey.shade100,
                )),
                lineBarsData: lineBarsData,
                // TODO readd betweenBarsData
                // TODO limit betweenBarsData to vertical/only on MW
                // betweenBarsData: [BetweenBarsData(fromIndex: 0, toIndex: 1)],
                minY: 0,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        );
                        var duration = Duration(seconds: value.toInt());

                        return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: (duration.inSeconds.remainder(60) != 0)
                                ? Text(
                                    '${duration.inMinutes}:${duration.inSeconds.remainder(60)}',
                                    style: style)
                                : Text('${duration.inMinutes}', style: style));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                //TODO borderData: FlBorderData(show: false))),
                //TODO gridData: FlGridData(),
              ),
            )));
  }
}
