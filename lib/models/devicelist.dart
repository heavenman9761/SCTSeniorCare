class DeviceList {
  final String deviceID;
  final String deviceType;
  final String accountID;
  final String lastState;
  final String createTime;

  DeviceList(
      {
      required this.deviceID,
      required this.deviceType,
      required this.accountID,
      required this.lastState,
      required this.createTime,
      });

  Map<String, dynamic> toMap() {
    return {
      'deviceID': deviceID,
      'deviceType': deviceType,
      'accountID': accountID,
      'lastState' : lastState,
      'createTime': createTime,
    };
  }

  @override
  String toString() {
    return 'DeviceList {title: $deviceID, text: $deviceID, deviceType: $deviceType, accountID: $accountID, lastState: $lastState, createTime: $createTime, }';
  }
}
