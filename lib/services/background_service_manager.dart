import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'Processing Service', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.low, // low importance = no sound/vibration
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    }

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        // This will be executed when app is in foreground or background in distinct isolate
        onStart: onStart,

        // auto start service
        autoStart: false,
        isForegroundMode: true,

        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Skarmy',
        initialNotificationContent: 'Initializing background service...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> startService() async {
    if (await _service.isRunning()) return;
    await _service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("stopService");
    }
  }

  static void updateNotificationContent(
    String content, {
    int? progress,
    int? max,
  }) {
    _service.invoke("updateNotification", {
      "content": content,
      "progress": progress,
      "max": max,
    });
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize the plugin for the background isolate
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listen for events from the UI isolate
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    service.on('updateNotification').listen((event) async {
      final String? content = event?['content'];
      final int progress = event?['progress'] ?? 0;
      final int max = event?['max'] ?? 0;
      final bool showProgress = max > 0;

      if (content != null) {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            flutterLocalNotificationsPlugin.show(
              888,
              'Skarmy Processing',
              content,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'my_foreground',
                  'Processing Service',
                  icon: '@mipmap/launcher_icon',
                  ongoing: true,
                  showProgress: showProgress,
                  maxProgress: max,
                  progress: progress,
                ),
              ),
            );
          }
        }
      }
    });
    
    // Bring to foreground
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
    
    // Keep alive loop
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // heartbeat
          service.invoke('heartbeat');
        }
      }
    });

    print("Background Service Started");
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }
}
