enum MQTTAppConnectionState { connected, disconnected, connecting, connectedSubscribed, connectedUnSubscribed }
class MQTTAppState{
  MQTTAppConnectionState _appConnectionState = MQTTAppConnectionState.disconnected;
  String _receivedText = '';
  String _historyText = '';
  String _receivedTopic = '';

  void setReceivedText(String text) {
    _receivedText = text;
    _historyText = _historyText + '\n' + _receivedText;
  }

  void setReceivedTopic(String topic) {
    _receivedTopic = topic;
  }

  void setAppConnectionState(MQTTAppConnectionState state) {
    _appConnectionState = state;
  }

  void clearText() {
    _historyText = "";
    _receivedText = "";
  }

  String get getReceivedText => _receivedText;
  String get getHistoryText => _historyText;
  String get getReceivedTopic => _receivedTopic;
  MQTTAppConnectionState get getAppConnectionState => _appConnectionState;

}