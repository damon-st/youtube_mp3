import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:youtube_mp3/services/notifications_service.dart';

abstract class Utils {
  static const method = MethodChannel("com.damon.youtube/directory");

  static Future<String?> getDowloadDirectory() async {
    try {
      return await method.invokeMethod("getDowload");
    } on PlatformException catch (e) {
      print(e);
      return null;
    }
  }
}

void showNotification(String title, String msg) {
  flutterLocalNotificationsPlugin.show(
    666,
    title,
    msg,
    NotificationDetails(
      android: AndroidNotificationDetails(channel.id, channel.name,
          channelDescription: channel.description,
          visibility: NotificationVisibility.public,
          color: Colors.blue,
          playSound: false,
          enableVibration: false,
          importance: Importance.min,
          icon: '@mipmap/ic_launcher'),
      iOS: IOSNotificationDetails(
        presentSound: false,
        subtitle: channel.description,
      ),
    ),
  );
}

void descargarMp3(Params params) async {
  try {
    await Dio().download(params.url, params.path,
        onReceiveProgress: (rec, total) {
      String progres = "${((rec / total) * 100).toStringAsFixed(0)}%";

      params.sendPort.send(progres);
    });
  } catch (e) {
    params.sendPort.send(e.toString());
  }
}

class Params {
  String url;
  String path;
  SendPort sendPort;
  Params({
    required this.path,
    required this.sendPort,
    required this.url,
  });
}
