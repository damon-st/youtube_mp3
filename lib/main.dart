import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:youtube_mp3/pages/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Wakelock.enable();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Descargar Mp3',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
