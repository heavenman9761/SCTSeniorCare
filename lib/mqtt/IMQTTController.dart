import 'package:flutter/cupertino.dart';

import 'package:mobile/mqtt/MQTTAppState.dart';

abstract class IMQTTController extends ChangeNotifier {

  MQTTAppState get currentState;
  String? get host;
  void initializeMQTTClient({
    required String host,
    required String identifier,
  });

  void connect();
  void disconnect();
  // void publish(String message);
  void publishTopic(String topic, String message);
  void subScribeTo(String topic);
  void unSubscribe(String topic);
  void unSubscribeFromCurrentTopic(String topic);
}