class Sensor {
  final String? deviceID;
  final String? deviceType;
  final Map<String, dynamic> state;

  String? getDeviceID() {
    return deviceID;
  }

  String? getDeviceType() {
    return deviceType;
  }

  Sensor({required this.deviceID, required this.deviceType, required this.state});

  Map<String, dynamic> toMap() {
    return {
      'deviceID': deviceID ?? '',
      'device_type': deviceType ?? '',
      'state': state ?? '',
    };
  }

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
        deviceID: json['deviceID'],
      deviceType: json['deviceType'],
        state: json['state'],
    );
  }

  @override
  String toString() {
    return 'Sensor{deviceID: $deviceID, deviceType: $deviceType, state: $state}';
  }
}
