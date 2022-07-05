import 'dart:async';
import 'dart:io';

import 'package:drishti/resources/theme_data.dart';
import 'package:drishti/screens/home/screen.dart';
import 'package:drishti/screens/init/screen.dart';
import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';

import 'package:flutter/services.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
  ));

  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeData,
      title: 'drishti',
      home: SplashScreen(cameras: cameras),
      debugShowCheckedModeBanner: false,
    );
  }
}
