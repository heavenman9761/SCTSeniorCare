import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'utils/firebase_options.dart';

import 'package:mobile/pages/login_page.dart';
import 'package:mobile/pages/Intro_page.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/pages/setting_hub_page.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

var loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();

  print("백그라운드 메시지 처리.. ${message.notification!.body!}");

  showFlutterNotification(message);
}

late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {

  RemoteNotification? notification = message.notification;

  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null && !kIsWeb) {

    print('showFlutterNotification() - ${notification.hashCode} ${notification.title} ${notification.body}');

    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'high_importance_notification',
          importance: Importance.max,
          // channel.id,
          // channel.name,
          // channelDescription: channel.description,
          // TODO add a proper drawable resource to android, for now using
          //      one that already exists in example app.
          //icon: 'launch_background',
        ),
      ),
    );
  }
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void initializeNotification() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
      'high_importance_channel',
      'high_importance_notification',
      importance: Importance.max
  ));

  await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings("@mipmap/ic_launcher"),
  ));

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  initializeNotification();

  runApp(const ProviderScope(child: MyApp()));
}

const seedColor = Color(0xff00ffff);

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(Controller());

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
        useMaterial3: true,
        // textTheme: GoogleFonts.notoSansNKoTextTheme(
        //   Theme.of(context)
        //       .textTheme, // If this is not set, then ThemeData.light().textTheme is used.
        // ),
      ),
      // initialRoute: '/',
      // getPages: [
      //   GetPage(name: '/', page: () => const HomePage(title: 'SCT Senior Care',)),
      //   //GetPage(name: '/Setting_Hub', page: () => SettingHub(hubName: Get.find<Controller>().hubName.value)),
      //   GetPage(name: '/Setting_Hub/:hubName', page: () => SettingHub()),
      // ],
      home: FutureBuilder(
        future: Future.delayed(const Duration(seconds: 3), () => "Intro Completed."),
        builder: (context, snapshot) {
          return AnimatedSwitcher(
              duration: const Duration(milliseconds: 2000),
              transitionBuilder: (Widget child, Animation<double> animation) {
                //return ScaleTransition(child: child, scale: animation);
                return FadeTransition(opacity: animation, child: child);
              },
              child: _splashLoadingWidget(snapshot),

          );
        },
      )
    );
  }

  Widget _splashLoadingWidget(AsyncSnapshot<Object?> snapshot) {
    if(snapshot.hasError) {
      return const Text("Error!!");
    } else if(snapshot.hasData) {
      return isLogin() ? const HomePage(title: 'SCT Senior Care') : const LoginPage();
    } else {
      return const IntroScreen();
    }
  }

  bool isLogin() {
    return true;//Get.find<Controller>().isLogin.value;
  }
}
