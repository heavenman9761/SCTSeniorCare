class AccessPoint {
  final String? WifiName;
  final int? rssi;
  final int? security;
  final String? password;

  String? getWifiName() {
    return WifiName;
  }

  int? getRssi() {
    return rssi;
  }

  int? getSecurity() {
    return security;
  }

  String? getPassword() {
    return password;
  }

  AccessPoint({required this.WifiName, required this.rssi, required this.security, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'WifiName': WifiName ?? '',
      'rssi': rssi ?? '',
      'security': security ?? '',
      'password': password ?? '',
    };
  }

  factory AccessPoint.fromJson(Map<String, dynamic> json) {
    return AccessPoint(
        WifiName: json['WifiName'],
      rssi: json['rssi'],
      security: json['security'],
      password: json['password']
    );
  }

  @override
  String toString() {
    return 'AccessPoint{WifiName: $WifiName, rssi: $rssi, security: $security, password: $password}';
  }
}
