import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mobile/mqtt/IMQTTController.dart';
import 'package:mobile/mqtt/MQTTAppState.dart';
import 'package:logger/logger.dart';
var logger = Logger(
  printer: PrettyPrinter(),
);

class MQTTManager extends IMQTTController {
  // Private instance of client
  MQTTAppState _currentState = MQTTAppState();
  MqttServerClient? _client;
  late String _identifier;
  String? _host;
  // String _topic = "";

  @override
  void initializeMQTTClient({
    required String host,
    required String identifier,
  }) {
    // Save the values
    // TODO: If already connected throw error
    // TODO: Remove forced unwrap usage and assertion
    _identifier = identifier;
    _host = host;
    _client = MqttServerClient(_host!, _identifier);
    _client!.port = 6002;//1883;
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = onDisconnected;
    _client!.secure = false;
    _client!.logging(on: true);

    /// Add the successful connection callback
    _client!.onConnected = onConnected;
    _client!.onSubscribed = onSubscribed;
    _client!.onUnsubscribed = onUnsubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .withWillTopic(
        'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
    .authenticateAs("mings", "Sct91234!")// Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    _client!.connectionMessage = connMess;
  }

  String? get host => _host;
  MQTTAppState get currentState => _currentState;
  // Connect to the host
  @override
  void connect() async {
    assert(_client != null);
    try {
      print('EXAMPLE::Mosquitto start client connecting....');
      _currentState.setAppConnectionState(MQTTAppConnectionState.connecting);
      updateState();
      await _client!.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      disconnect();
    }
  }

  @override
  void disconnect() {
    print('Disconnected');
    _client!.disconnect();
  }

  @override
  // void publish(String message) {
  //   final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  //   builder.addString(message);
  //   _client!.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
  // }

  @override
  void publishTopic(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  /// The subscribed callback
  @override
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
    _currentState
        .setAppConnectionState(MQTTAppConnectionState.connectedSubscribed);
    updateState();
  }

  @override
  void onUnsubscribed(String? topic) {
    print('EXAMPLE::onUnsubscribed confirmed for topic $topic');
    _currentState.clearText();
    _currentState
        .setAppConnectionState(MQTTAppConnectionState.connectedUnSubscribed);
    updateState();
  }

  /// The unsolicited disconnect callback
  @override
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (_client!.connectionStatus!.returnCode ==
        MqttConnectReturnCode.noneSpecified) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
    _currentState.clearText();
    _currentState.setAppConnectionState(MQTTAppConnectionState.disconnected);
    updateState();
  }

  /// The successful connect callback
  @override
  void onConnected() {
    _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    updateState();

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
      _currentState.setReceivedTopic(c[0].topic);
      _currentState.setReceivedText(pt);
      updateState();
      // logger.i('[${c[0].topic}] $pt');
    });
  }

  @override
  void subScribeTo(String topic) {
    // Save topic for future use
    // _topic = topic;
    _client!.subscribe(topic, MqttQos.atLeastOnce);
  }

  /// Unsubscribe from a topic
  @override
  void unSubscribe(String topic) {
    _client!.unsubscribe(topic);
  }

  /// Unsubscribe from a topic
  @override
  void unSubscribeFromCurrentTopic(String topic) {
    _client!.unsubscribe(topic);
  }

  void updateState() {
    //controller.add(_currentState);
    notifyListeners();
  }
}
