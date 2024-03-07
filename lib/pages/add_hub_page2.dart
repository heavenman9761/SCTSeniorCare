import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/Constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/Providers.dart';
import 'package:mobile/models/accesspoint.dart';
import 'package:mobile/mqtt/IMQTTController.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

var loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

enum ConfigState {none,
  findingHub, findingHubError, findingHubPermissionError, findingHubDone,
  settingMqtt, settingMqttError, settingMqttDone,
  settingWifiScan, settingWifiScanError, settingWifiScanDone,
  settingWifi, settingWifiError, settingWifiDone}

class AddHubPage2 extends ConsumerStatefulWidget {
  const AddHubPage2({super.key});

  @override
  ConsumerState<AddHubPage2> createState() => _AddHubPage2State();
}

class _AddHubPage2State extends ConsumerState<AddHubPage2> {

  ConfigState configState = ConfigState.none;
  List<String> _esp32DeviceNames = [];
  final List<AccessPoint> _apList = [];
  late AccessPoint selectedAp;
  String wifiPassword = "";
  String hubID = "";
  late IMQTTController _manager;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> setHubIdToPrefs(String value) async {
    try {
      final SharedPreferences pref = await SharedPreferences.getInstance();

      pref.setString('deviceID', value).then((bool success) {
        if (success) {
          _manager.subScribeTo('result/$value');
          logger.i('subscribed to result/$value');
        }
      });
    } catch (error) {
      logger.e(error);
    }
  }

  @override
  void initState() {
    setState(() {
      configState = ConfigState.none;
      findHub();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> findHub() async {
    print("================= findHub()");
    List<String> esp32DeviceNames;
    try {
      setState(() {
        configState = ConfigState.findingHub;
      });
      final Iterable result =
          await Constants.platform.invokeMethod('findEsp32');
      esp32DeviceNames = result.cast<String>().toList();
      print("dart: " + esp32DeviceNames.toString());

      setState(() {
        configState = ConfigState.findingHubDone;
      });


      //deviceName = '$result';
    } on PlatformException catch (e) {
      if (e.message!.contains('permission')) {
        print("permission error");
        setState(() {
          configState = ConfigState.findingHubPermissionError;
        });

      } else {
        //snackbar("${e.message}");
        setState(() {
          configState = ConfigState.findingHubError;
        });

      }
      esp32DeviceNames = [];
    }

    setState(() {
      _esp32DeviceNames = esp32DeviceNames;
    });
  }

  Future<void> _settingHub() async {
    print("================= _settingHub()");
    try {
      setState(() {
        configState = ConfigState.settingMqtt;
      });

      final String result =
          await Constants.platform.invokeMethod('settingHub', <String, dynamic>{
        "hubName": _esp32DeviceNames[0],
        "accountID": "dn9318dn@gmail.com",
        "serverIp": "14.42.209.174",
        "serverPort": "6002",
        "userID": "mings",
        "userPw": "Sct91234!"
      });

      hubID = result;

      print('received from java [hubID]: ${hubID}');

      setState(() {
        configState = ConfigState.settingMqttDone;
      });

      _wifiScan();
    } on PlatformException catch (e) {
      print(e.message);
      setState(() {
        configState = ConfigState.settingMqttError;
      });
    }
  }

  Future<void> _wifiScan() async {
    print("================= _wifiProvision()");
    String strApList;

    try {
      setState(() {
        configState = ConfigState.settingWifiScan;
      });

      final result = await Constants.platform.invokeMethod('_wifiProvision');
      strApList = result.toString();
      print(strApList);

      List<dynamic> list = json.decode(strApList);

      for (int i = 0; i < list.length; i++) {
        AccessPoint ap = AccessPoint.fromJson(list[i]);
        print(ap.toString());
        _apList.add(ap);
      }


      setState(() {
        configState = ConfigState.settingWifiScanDone;
        if (_apList.isNotEmpty) {
          showWifiDialog(context);
        }
      });
    } on PlatformException catch (e) {
      setState(() {
        configState = ConfigState.settingWifiScanError;
      });

      print(e.message);
    }
  }

  Future<void> _setWifiConfig() async {
    print("================= _setWifiConfig()");
    try {
      setState(() {
        configState = ConfigState.settingWifi;
      });

      print("_setWifiConfig() ${wifiPassword} ${selectedAp.toString()}");
      final String result = await Constants.platform.invokeMethod(
          'setWifiConfig', <String, dynamic>{
        "wifiName": selectedAp.getWifiName(),
        "password": wifiPassword
      });
      print('received from java: ${result}');

      setState(() {
        configState = ConfigState.settingWifiDone;
        setHubIdToPrefs(hubID);
      });
    } on PlatformException catch (e) {
      print(e.message);
      setState(() {
        configState = ConfigState.settingWifiError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _manager = ref.watch(mqttManagerProvider);
    final hub = ref.watch(hubNameProvider);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Find IoT Hub'),
        ),
        body: Center(child: controlUI()));
  }

  Widget controlUI() {
    if (configState == ConfigState.findingHub) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20,),
          Text("허브를 찾고 있습니다.")
        ],
      );
    } else {
      if (_esp32DeviceNames.isEmpty) {
        if (configState == ConfigState.findingHubDone) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: findHub, child: const Text('다시 시도')),
              SizedBox(height: 20,),
              const Text("허브를 찾을 수 없습니다.\n다시 시도해보시기 바랍니다.")
          ]);
        } else if (configState == ConfigState.findingHubError) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: findHub, child: const Text('다시 시도')),
              SizedBox(height: 20,),
              const Text("오류가 발생 했습니다.\n다시 시도해보시기 바랍니다.")
          ]);
        }
      } else {
        if (configState == ConfigState.findingHubError
            || configState == ConfigState.settingMqttError
            || configState == ConfigState.settingWifiScanError
            || configState == ConfigState.settingWifiError) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: findHub, child: const Text('다시 시도')),
              SizedBox(height: 20,),
              const Text("오류가 발생 했습니다.\n다시 시도해보시기 바랍니다.")
          ]);
        } else if (configState == ConfigState.findingHubPermissionError) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: findHub, child: const Text('찾기')),
              SizedBox(height: 20,),
              const Text("사용 권한을 부여해주시고\n다시 시도해보시기 바랍니다.")
          ]);
        } else if (configState == ConfigState.findingHubDone) {
          _settingHub();
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20,),
              Text('설정 중 입니다.')
            ],
          );
        } else if (configState == ConfigState.settingMqtt
            || configState == ConfigState.settingMqttDone
            || configState == ConfigState.settingWifiScan
            || configState == ConfigState.settingWifiScanDone
            || configState == ConfigState.settingWifi) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20,),
              Text('설정 중 입니다.')
            ],
          );
        } else if (configState == ConfigState.settingWifiDone) {
          return lastWidget();
        }
      }
      return Text('');
    }
  }

  Widget lastWidget()
  {

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('설정이 완료되었습니다.')
      ],
    );
  }

  void showWifiDialog(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
                title: const Text("Select WIFI"),
                content: ListView.builder(
                  itemCount: _apList.length,
                  itemBuilder: (BuildContext ctx, int idx) {
                    return ListTile(
                      title: Text(_apList[idx].getWifiName()!),
                      leading: RssiWidget(_apList[idx]),
                      trailing: _apList[idx].getSecurity() == 0
                          ? const Icon(Icons.lock_open)
                          : const Icon(Icons.lock),
                      onTap: () {
                        Navigator.pop(context, _apList[idx]);
                      },
                    );
                  }
                ),
                actions: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); //창 닫기
                    },
                    child: const Text("취소"),
                  ),
                ],
            );

          });
        }).then((val) {
          if (val != null) {
            selectedAp = val;
            print("selectedAp : ${val}");
            inputWifiPasswordDialog(context);
          }
    });
  }

  Widget RssiWidget(AccessPoint ap) {
    if (ap.getRssi()! > -50) {
      return const Icon(Icons.wifi);
    } else if (ap.getRssi()! >= -60) {
      return const Icon(Icons.wifi_2_bar);
    } else if (ap.getRssi()! >= -67) {
      return const Icon(Icons.wifi_2_bar);
    } else {
      return const Icon(Icons.wifi_1_bar);
    }
  }

  void inputWifiPasswordDialog(BuildContext context) {
    final controller = TextEditingController(text: "");
    bool passwordVisible = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text("Input WIFI Password"),
              content: TextFormField(
                obscureText: passwordVisible,
                controller: controller,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() => passwordVisible = !passwordVisible);
                    },
                  ),
                  labelText: 'Password',
                  icon: const Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: Icon(Icons.lock),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.pop(context, controller.text);
                  },
                ),
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((val) {
      if (val != null) {
        setState(() {
          wifiPassword = val;
          _setWifiConfig();
        });
      }
    });
  }


}
