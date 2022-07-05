import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:localstore/localstore.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_speech/flutter_speech.dart';
import 'package:drishti/utils/strring_msg_constants.dart';
import 'dart:io';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:sound_mode/permission_handler.dart';

class Bloc {
  List<CameraDescription>? cameras;
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  FlutterTts flutterTts = new FlutterTts();
  late SpeechRecognition _speech;
  bool _speechRecognitionAvailable = false;
  int counter = 0;
  XFile? imageFile;
  var log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 1,
      colors: true,
      printEmojis: false,
    ),
  );
  final db = Localstore.instance;

  // camera initilialization handler
  final cameraInitCheckerController = BehaviorSubject<bool>.seeded(false);

  Stream<bool> get cameraInitCheckerStream =>
      cameraInitCheckerController.stream;

  Function(bool)? get setCameraInitCheckerStream =>
      cameraInitCheckerController.isClosed
          ? null
          : cameraInitCheckerController.sink.add;

  // image count
  final imageCountController = BehaviorSubject<int>.seeded(0);

  Stream<int> get imageCountStream => imageCountController.stream;

  Function(int)? get setimageCountStream =>
      imageCountController.isClosed ? null : imageCountController.sink.add;

  // camera initilialization handler
  final apiImageTextController = BehaviorSubject<String>.seeded("");

  Stream<String> get apiImageTextStream => apiImageTextController.stream;

  Function(String)? get setApiImageTextStream =>
      apiImageTextController.isClosed ? null : apiImageTextController.sink.add;

  // ai logo size
  final voiceAnimationController = BehaviorSubject<bool>.seeded(false);

  Stream<bool> get voiceAnimationStream => voiceAnimationController.stream;

  Function(bool)? get setVoiceAnimationStream =>
      voiceAnimationController.isClosed
          ? null
          : voiceAnimationController.sink.add;

  // level
  final stageLevelController = BehaviorSubject<int>.seeded(1);

  Stream<int> get stageLevelStream => stageLevelController.stream;

  Function(int)? get setstageLevelStream =>
      stageLevelController.isClosed ? null : stageLevelController.sink.add;

  // speech  status
  final speechStatusController = BehaviorSubject<String>.seeded("Stop");

  Stream<String> get speechStatusStream => speechStatusController.stream;

  Function(String)? get setSpeechStatusStream =>
      speechStatusController.isClosed ? null : speechStatusController.sink.add;

  // mic status start,stop
  final micController = BehaviorSubject<String>.seeded("Stop");

  Stream<String> get micStream => micController.stream;

  Function(String)? get setMicStream =>
      micController.isClosed ? null : micController.sink.add;

  // ai logo size
  final isImageProController = BehaviorSubject<bool>.seeded(false);

  Stream<bool> get isImageProStream => isImageProController.stream;

  Function(bool)? get setIsImageProStream =>
      isImageProController.isClosed ? null : isImageProController.sink.add;

  // ai logo size
  final micStatusController = BehaviorSubject<bool>.seeded(false);

  Stream<bool> get micStatusStream => micStatusController.stream;

  Function(bool)? get setmicStatusStream =>
      micStatusController.isClosed ? null : micStatusController.sink.add;

  // start clicking pictures
  void start() async {
    _speak("Taking a picture");
    controller.takePicture().then((image) async {
      setIsImageProStream!(true);
      log.v("Took a picture");
      counter++;
      setimageCountStream!(counter);
      String text = await upload(image);

      text = text.replaceAll('.', "");

      _speak(text);
      log.v(text);
      setApiImageTextStream!(text);
      setIsImageProStream!(false);
    });
  }

  Future<String> upload(XFile imageFile) async {
    //create multipart request for POST or PATCH method
    var request = http.MultipartRequest(
        "POST", Uri.parse("https://safe-wildwood-63988.herokuapp.com/upload"));
    //add text fields

    //create multipart using filepath, string or bytes
    var pic = await http.MultipartFile.fromPath("image", imageFile.path,
        filename: "image");
    //add multipart to request

    request.files.add(pic);
    log.v("Image sent. waiting for the result...");
    try {
      var response = await request.send().timeout(Duration(seconds: 30));

      //Get the response from the server
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      Map text = json.decode(responseString);
      log.v(text);
      return text["result"];
    } catch (e) {
      return MessageText.app_image_error;
    }
  }

  // text to speech
  Future _setVoice() async {
    await flutterTts.setSpeechRate(0.44);
    await flutterTts.setPitch(0.95);
    await flutterTts.setVoice({"name": "en-us-x-tpf-local", "locale": "en-US"});

    // ai size animation
    flutterTts.setProgressHandler(
        (String text, int startOffset, int endOffset, String word) {
      setVoiceAnimationStream!(!voiceAnimationController.value);
    });

    flutterTts.setStartHandler(() {
      setSpeechStatusStream!("Start");
      setMicStream!("Stop");
    });

    flutterTts.setCompletionHandler(() {
      setSpeechStatusStream!("Stop");

      // stage 1 completed
      if (stageLevelController.value == 1) {
        setstageLevelStream!(2);
        log.v({
          "stage": stageLevelController.value,
          "level": "listen to user commands"
        });
        setMicStream!("Start");
      }

      if (stageLevelController.value == 2) {
        Timer(Duration(seconds: 2), () {
          setMicStream!("Start");
        });
      }

      if (stageLevelController.value == 3) {
        exit(0);
      }
    });
  }

  Future _speak(String text) async {
    await flutterTts.speak(text);
  }

  void activateSpeechRecognizer() {
    _speech = SpeechRecognition();
    _speech.setErrorHandler(errorHandler);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech.activate('en_US').then((res) {
      _speechRecognitionAvailable = res;
    });
  }

  void errorHandler() {
    log.v("Mic error");

    setmicStatusStream!(false);
    if (stageLevelController.value == 2) {
      if (micController.value != "Stop") {
        _speak("");
      }
    }
  }

  void onRecognitionResult(String words) {
    log.v({"text recived ": words});

    if (words.toLowerCase().contains("take a picture")) {
      if (!isImageProController.value) {
        start();
        setMicStream!("Stop");
      }
    } else if (words.toLowerCase().contains("stop")) {
      setMicStream!("Stop");
      _speak("I am closing the app, see you soon");
      setstageLevelStream!(3);
    } else {
      errorHandler();
      log.v({"Text not found"});
    }
  }

  void onRecognitionComplete(String input) {
    log.v({"input ": input});
  }

  void initlizePlugins() {
    log.v("Initializing voice and mic");
    _setVoice();
    activateSpeechRecognizer();
  }

  void removeName() {
    db.collection('names').doc("n1").delete();
  }

  void startListening() {
    log.v("listening...");
    if (speechStatusController.value != "Start") {
      setmicStatusStream!(true);
      _speech.listen();
    }
  }

  init(cameras) async {
    initlizePlugins();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      setCameraInitCheckerStream!(true);
      log.v("Camara started");
      Timer(Duration(seconds: 2), () {
        log.v({"stage": stageLevelController.value, "level": "Intructions"});
        _speak(MessageText.app_start_messege);
      });
      return;
    });

    micController.listen((value) {
      if (value == "Start") {
        startListening();
      } else {
        _speech.stop();
      }
    });

    var isGranted = await PermissionHandler.permissionsGranted ?? false;

    if (!isGranted) {
      // Opens the Do Not Disturb Access settings to grant the access
      await PermissionHandler.openDoNotDisturbSetting();
    }

    isImageProController.listen((value) async {
      var ringerStatus = await SoundMode.ringerModeStatus;
      log.v(ringerStatus);
      if (value) {
        try {
          await SoundMode.setSoundMode(RingerModeStatus.silent);
        } catch (e) {
          print('Please enable permissions required');
        }
      } else {
        try {
          await SoundMode.setSoundMode(RingerModeStatus.normal);
        } catch (e) {
          print('Please enable permissions required');
        }
      }
    });
  }

  void dispose() {
    controller.dispose();

    // plugins close
    flutterTts.stop();
    _speech.stop();
  }
}
