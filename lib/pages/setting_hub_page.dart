import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile/Constants.dart';
import 'package:mobile/models/accesspoint.dart';

class SettingHub extends StatefulWidget {
  SettingHub({super.key, required this.hubName});

  String hubName;
  @override
  State<SettingHub> createState() => _SettingHubState();
}

class _SettingHubState extends State<SettingHub> {
  // final String hubName = Get.arguments['hubName'];

  final List<AccessPoint> _apList = [];
  String wifiPassword = "";
  late AccessPoint selectedAp;
  late String hubID;

  @override
  void initState() {
    super.initState();
    _settingHub();
  }

  Future<void> _settingHub() async {
    try {
      final String result =
          await Constants.platform.invokeMethod('settingHub', <String, dynamic>{
        "hubName": widget.hubName,
        "accountID": "dn9318dn@gmail.com",
        "serverIp": "14.42.209.174",
        "serverPort": "6002",
        "userID": "mings",
        "userPw": "Sct91234!"
      });

      hubID = result;
      print('received from java: ${result}');

      _wifiProvision();
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> _setWifiConfig() async {
    try {
      print("_setWifiConfig() ${wifiPassword}");
      final String result = await Constants.platform.invokeMethod('setWifiConfig', <String, dynamic> {
        "wifiName": selectedAp.getWifiName(),
        "password": wifiPassword
      });
      print('received from java: ${result}');

    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> _wifiProvision() async {
    String strApList;
    try {
      final result = await Constants.platform.invokeMethod('_wifiProvision');
      strApList = result.toString();
      print(strApList);

      List<dynamic> list = json.decode(strApList);

      for (int i = 0; i < list.length; i++) {
        AccessPoint ap = AccessPoint.fromJson(list[i]);
        // print(ap.toString());
        _apList.add(ap);
      }

      setState(() {});
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<List<AccessPoint>> _viewApList() async {
    if (_apList.isNotEmpty) {
      return _apList;
    } else {
      List<AccessPoint> list = [];

      await Future.delayed(const Duration(seconds: 1));
      return list;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Setting Hub ($widget.hubName)'),
        ),
        body: FutureBuilder<List<AccessPoint>>(
            future: _viewApList(),
            builder: (context, snapshot) {
              final List<AccessPoint>? apList = snapshot.data;
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child:
                      CircularProgressIndicator(backgroundColor: Colors.blue),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              }
              if (snapshot.hasData) {
                if (apList != null) {
                  if (apList.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                          backgroundColor: Colors.blue),
                    );
                  }
                  return ListView.builder(
                    itemCount: apList.length,
                    itemBuilder: (context, index) {
                      final AccessPoint ap = apList[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: ListTile(
                            title: Text(ap.getWifiName()!),
                            trailing: ap.getSecurity() == 0
                                ? const Icon(Icons.lock_open)
                                : const Icon(Icons.lock),
                            leading: RssiWidget(ap),
                            onTap: () {
                              selectedAp = ap;
                              if (ap.getSecurity()! > 0) {
                                inputWifiPasswordDialog(context);
                              } else {
                                wifiPassword = "";
                                _setWifiConfig();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child:
                        CircularProgressIndicator(backgroundColor: Colors.blue),
                  );
                }
              } else {
                return const Center(
                  child:
                      CircularProgressIndicator(backgroundColor: Colors.blue),
                );
              }
            }
          )
    );
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
