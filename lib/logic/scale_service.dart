import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:eventsource/eventsource.dart';
import 'package:flutter/material.dart';

enum ScaleConnectionState {
  disconnected,
  connecting,
  connected,
  lostConnection,
  ipNotFound,
  timeout,
}

// as per https://esphome.io/web-api/#event-source-api
enum ScaleEventType {
  log,
  state,
  ping,
}

class ScaleService extends ChangeNotifier {
  EventSource? _scale;
  String ip = '192.168.4.1';

  ScaleConnectionState connectionState = ScaleConnectionState.disconnected;

  int? _lastWeight;
  int? get taredLastWeight =>
      (_lastWeight == null) ? null : (_lastWeight! - _tareValue);
  int _tareValue = 0;

  final DenoisingService _denoiser = DenoisingService();

  reConnectScale() {
    _lastWeight = null;
    _initEventSource();
  }

  ScaleService() {
    _initEventSource();
  }

  void _initEventSource() async {
    try {
      _scale = await EventSource.connect('http://$ip/events');
      connectionState = ScaleConnectionState.connecting;
      _scale!.listen((event) {
        //print('parsing event: ${event.data!}');

        _handleEventSourceEvent(event);
      });
    } on SocketException catch (e) {
      switch (e.message) {
        case "No route to host":
        case "Network is unreachable":
        case "Connection failed":
        case "Software caused connection abort":
          connectionState = ScaleConnectionState.ipNotFound;
          break;
        case "Connection timed out":
          connectionState = ScaleConnectionState.timeout;
          break;
        default:
          rethrow;
      }
    } finally {
      notifyListeners();
    }
  }

  void _handleEventSourceEvent(Event event) {
    ScaleEvent scaleEvent;

    try {
      scaleEvent = ScaleEvent.fromJson(event.data!);
    } on Exception catch (e) {
      if (e.toString() == 'Exception: invalid json event') {
        //print('ignoring non-json event');
        return;
      }
      rethrow;
    }

    switch (scaleEvent.type) {
      case ScaleEventType.log:
        connectionState = ScaleConnectionState.connected;
        break;
      case ScaleEventType.state:
        if (connectionState != ScaleConnectionState.connected) {
          connectionState = ScaleConnectionState.connected;
          print(
              'warning: unexpectedly received Scale status before scale log.');
        }
        if (scaleEvent.measurement != null) {
          _denoiser.addRawWeight(scaleEvent.measurement!);
          if (_lastWeight != null) {
            _lastWeight = _denoiser.getDenoisedWeight(_lastWeight!);
          } else {
            _lastWeight = _denoiser.getFirstRawWeight();
          }
        }
        break;
      default:
        throw UnimplementedError("Unimplemented Scale Event");
    }
    notifyListeners();
  }

  tareScale() {
    if (_lastWeight != null) {
      _tareValue = _lastWeight!;

      notifyListeners();
    }
  }
}

class DenoisingService {
  final Queue _rawWeights = Queue();
  DateTime? _lastRawWeightTimestamp;

  int getFirstRawWeight() {
    return _rawWeights.first;
  }

  void addRawWeight(int rawWeight) {
    if (_lastRawWeightTimestamp != null &&
        _lastRawWeightTimestamp!.difference(DateTime.now()) >
            const Duration(seconds: 2)) {
      print(
          '${_lastRawWeightTimestamp!.difference(DateTime.now())} sec til last raw weight. clearing _rawWeights ');
      _rawWeights.clear();
    }
    if (_rawWeights.length >= 3) {
      _rawWeights.removeFirst();
    }
    _rawWeights.add(rawWeight);
    _lastRawWeightTimestamp = DateTime.now();
  }

  /// returns the weight that has the smallest deviation to [lastWeight]
  /// (the last denoised weight), out of the 3 last measured [_rawWeights],
  /// or the oldest if they are less than 3.
  int getDenoisedWeight(int lastWeight) {
    if (_rawWeights.length < 3) {
      return _rawWeights.first;
    }
    Map<int, int> rawWeightsByDeviation = {};
    for (int rawWeight in _rawWeights) {
      int deviation = (rawWeight - lastWeight).abs();
      rawWeightsByDeviation[deviation] = rawWeight;
    }
    int smallestDeviation = rawWeightsByDeviation.keys.first;
    for (var deviation in rawWeightsByDeviation.keys) {
      smallestDeviation = min(smallestDeviation, deviation);
    }
    var denoisedWeight = rawWeightsByDeviation[smallestDeviation]!;
    print('weight (denoised): $denoisedWeight');
    return denoisedWeight;
  }
}

/// Decode the Scales EventSource-Events from json
class ScaleEvent {
//  final String timestamp;
  late final int? measurement;
  late final ScaleEventType type;

  ScaleEvent.fromJson(String jsonString) {
    validateJson(jsonString);

    Map<String, dynamic> json = jsonDecode(jsonString);
    if (json.keys.contains("log")) {
      type = ScaleEventType.log;
      return;
    }
    if (json.keys.contains("state")) {
      type = ScaleEventType.state;
      var measurementString = json['state'] as String;
      if (measurementString.endsWith(' g')) {
        measurement = int.parse(
            measurementString.substring(0, measurementString.length - 2));
      } else {
        if (measurementString.endsWith('g')) {
          throw Exception(
              'unit of measurement parsing in $measurementString not implemented');
        }
      }
      return;
    }
    throw Exception("Scale Event Error: unexpected key combination");
  }

  void validateJson(String jsonString) {
    RegExp nonJsonEventExpr = RegExp(r'\[\w\]');
    // this regex is flaky but does help avoid excessive json parsing
    RegExp emptyEventExpr = RegExp(r'^$');

    if (nonJsonEventExpr.hasMatch(jsonString) ||
        emptyEventExpr.hasMatch(jsonString)) {
      throw Exception('invalid json event');
    }
  }
}
