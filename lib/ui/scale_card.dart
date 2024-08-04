import 'package:flutter/material.dart';
import 'package:meal_trainer/logic/scale_service.dart';
import 'package:meal_trainer/ui/page_scale_setup.dart';
import 'package:provider/provider.dart';

class ScaleCard extends StatefulWidget {
  const ScaleCard({
    required this.hasLinkToScaleSetup,
    super.key,
  });

  final bool hasLinkToScaleSetup;

  @override
  State<ScaleCard> createState() => _ScaleCardState();
}

class _ScaleCardState extends State<ScaleCard> {
  late ScaleService _scaleService;
  late String displayedMeasurement;

  @override
  void didChangeDependencies() {
    _scaleService = context.watch<ScaleService>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    bool isEmphasized;

    switch (_scaleService.connectionState) {
      case ScaleConnectionState.ipNotFound:
      case ScaleConnectionState.timeout:
      case ScaleConnectionState.disconnected:
      case ScaleConnectionState.connecting:
      case ScaleConnectionState.lostConnection:
        displayedMeasurement = 'no connection';
        isEmphasized = false;
        break;
      case ScaleConnectionState.connected:
        displayedMeasurement = '${_scaleService.taredLastWeight ?? '-'} g';
        isEmphasized = true;
        break;
    }

    Color? containerColor, containerTextColor;
    if (!isEmphasized) {
      containerColor = Theme.of(context).colorScheme.tertiaryContainer;
      containerTextColor = Theme.of(context).colorScheme.onTertiaryContainer;
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Tooltip(
              message: 'Scale Status',
              child: Card(
                  color: containerColor,
                  elevation: 5,
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.fromLTRB(15, 15, 0, 15),
                        child: Column(children: [
                          Icon(
                              size: 32,
                              isEmphasized
                                  ? Icons.scale
                                  : Icons.scale_outlined),
                          const Text('SCALE'),
                        ])),
                    Container(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(displayedMeasurement,
                            style: (displayedMeasurement.length < 10)
                                // hacky. TODO remove, and simplify label
                                ? Theme.of(context)
                                    .textTheme
                                    .displayMedium!
                                    .copyWith(color: containerTextColor)
                                : Theme.of(context)
                                    .textTheme
                                    .displaySmall!
                                    .copyWith(color: containerTextColor))),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(children: [
                          if (widget.hasLinkToScaleSetup)
                            OutlinedButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ScaleSetupPage())),
                                child: const Text("setup")),
                          ElevatedButton(
                              onPressed: (_scaleService.connectionState ==
                                      ScaleConnectionState.connected)
                                  ? _scaleService.tareScale
                                  : null,
                              child: const Text(
                                  " tare ")), //TODO actually have buttons be same width
                        ])),
                  ])))),
    ]);
  }
}
