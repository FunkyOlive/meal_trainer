import 'package:flutter/material.dart';
import 'package:meal_trainer/ui/scale_card.dart';
import 'package:meal_trainer/ui/ui_components.dart';
import 'package:provider/provider.dart';

import '../logic/scale_service.dart';

class ScaleSetupPage extends StatefulWidget {
  const ScaleSetupPage({super.key, this.title = 'Scale Set Up'});

  final String title;

  @override
  State<ScaleSetupPage> createState() => _ScaleSetupPageState();
}

class _ScaleSetupPageState extends State<ScaleSetupPage> {
  late ScaleService _scaleService;
  // late BiteDetectionService _biteService;

  @override
  void didChangeDependencies() {
    _scaleService = context.watch<ScaleService>();
    // _biteService = context.watch<BiteDetectionService>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    //String displayedWeightAtBite = _biteService.value.toString();

    return Scaffold(
        appBar: UIcomponents.getAppBar(context, widget.title),
        drawer: UIcomponents.getDrawer(context),
        body: SingleChildScrollView(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
              const ScaleCard(
                hasLinkToScaleSetup: false,
              ),
              Text('scale State: ${_scaleService.connectionState.name}'),
              ButtonList(buttons: [
                ElevatedButton(
                    onPressed: _scaleService.reConnectScale,
                    child: const Text("restart connection")),
                OutlinedButton(
                    onPressed: () => showChangeIPDialog(context),
                    child: const Text("change IP")),
              ]),
              // const Icon(size: 64, Icons.rice_bowl),
              // Card(
              //     color: Theme.of(context).colorScheme.surface,
              //     elevation: 5,
              //     child: Padding(
              //         padding: const EdgeInsets.all(20.0),
              //         child: Text(displayedWeightAtBite,
              //             style: Theme.of(context)
              //                 .textTheme
              //                 .displayMedium!
              //                 .copyWith(
              //                   color: Theme.of(context).colorScheme.onSurface,
              //                 )))),
            ]))));
  }

  Future<dynamic> showChangeIPDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();

        return SimpleDialog(
            contentPadding: const EdgeInsets.fromLTRB(12, 24, 12, 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            children: <Widget>[
              Form(
                  key: formKey,
                  child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            initialValue: _scaleService.ip,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                                label: Text('Scale IP Address'),
                                border: OutlineInputBorder()),
                            onSaved: (newValue) => _scaleService.ip = newValue!,
                            // TODO use library for validation
                            validator: (value) => RegExp(
                                        '\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}')
                                    .hasMatch(value ?? '')
                                ? null
                                : 'please enter an ipv4 address of the format ddd.ddd.ddd.ddd')),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'))),
                      Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Change IP Address'))),
                    ]),
                  ])),
            ]);
      });
}
