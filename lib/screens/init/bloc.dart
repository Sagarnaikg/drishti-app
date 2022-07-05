import 'dart:async';
import 'package:localstore/localstore.dart';
import 'package:drishti/screens/home/screen.dart';
import 'package:drishti/utils/strring_msg_constants.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_speech/flutter_speech.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

class Bloc {
  // some initilization
  var log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 1,
      colors: true,
      printEmojis: false,
    ),
  );
  // speak sentence
  final db = Localstore.instance;
  final speakSentenceController = BehaviorSubject<String>.seeded("");

  Stream<String> get speakSentenceStream => speakSentenceController.stream;

  Function(String)? get setSpeakSentenceStream =>
      speakSentenceController.isClosed
          ? null
          : speakSentenceController.sink.add;

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

  // name
  final nameController = BehaviorSubject<String>.seeded("");

  Stream<String> get nameStream => nameController.stream;

  Function(String)? get setNameStream =>
      nameController.isClosed ? null : nameController.sink.add;

  // drishti title text
  final titleTextController = BehaviorSubject<String>.seeded("Drishti");

  Stream<String> get titleTextStream => titleTextController.stream;

  Function(String)? get setTitleTextStream =>
      titleTextController.isClosed ? null : titleTextController.sink.add;

  // ai logo size
  final voiceAnimationController = BehaviorSubject<bool>.seeded(false);

  Stream<bool> get voiceAnimationStream => voiceAnimationController.stream;

  Function(bool)? get setVoiceAnimationStream =>
      voiceAnimationController.isClosed
          ? null
          : voiceAnimationController.sink.add;

  // position top
  final positionTopController = BehaviorSubject<double>.seeded(100);

  Stream<double> get positionTopStream => positionTopController.stream;

  Function(double)? get setPositionTopStream =>
      positionTopController.isClosed ? null : positionTopController.sink.add;

  // position bottom
  final positionBottomController = BehaviorSubject<double>.seeded(100);

  Stream<double> get positionBottomStream => positionBottomController.stream;

  Function(double)? get setPositionBottomStream =>
      positionBottomController.isClosed
          ? null
          : positionBottomController.sink.add;

  // init
  // text to speech
  late Function moveNext;
  FlutterTts flutterTts = new FlutterTts();
  String voiceState = "Started";
  String sentence = "";
  // speech to text
  late SpeechRecognition _speech;
  bool _speechRecognitionAvailable = false;

  void activateSpeechRecognizer() {
    _speech = SpeechRecognition();
    _speech.setErrorHandler(errorHandler);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech.activate('en_US').then((res) {
      _speechRecognitionAvailable = res;
    });
  }

  void start() {
    if (stageLevelController.value == 2) {
      log.v("Tell name");
    }

    if (stageLevelController.value == 3) {
      log.v("Say start");
    }

    _speech.listen();
  }

  void errorHandler() {
    log.v("Mic error");

    if (stageLevelController.value == 2) {
      if (nameController.value == "") {
        log.v("Retrying to get name");
        if (speechStatusController.value != "Start") {
          _speak(MessageText.ask_Name_repeat);
        }
      }
    }

    if (stageLevelController.value == 3) {
      log.v("Retrying to get start command");
      if (speechStatusController.value != "Start") {
        _speak(MessageText.ask_start_repeat);
      }
    }
  }

  void onRecognitionResult(String words) {
    log.v({"text recived ": words});

    if (stageLevelController.value == 3) {
      if (words.contains("start")) {
        setstageLevelStream!(4);
        log.v("Stage 3 complated");
        moveNext();
      } else {
        Timer(Duration(seconds: 3), () {
          errorHandler();
        });
      }
    }
  }

  void onRecognitionComplete(String input) {
    if (stageLevelController.value == 2) {
      log.v({"name ": input});
      if (input != '') {
        setNameStream!(input);
        db.collection('names').doc('n1').set({
          "name": input,
        });
        _speech.stop();

        log.v(
            {"stage": stageLevelController.value, "level": "App instructions"});
        if (speechStatusController.value != "Start") {
          _speak(MessageText.getPersonalMessage(input));
        }

        Timer(Duration(seconds: 2), () {
          setstageLevelStream!(3);
        });
      }
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
    });

    flutterTts.setCompletionHandler(() {
      setSpeechStatusStream!("Stop");

      // stage 1 completed
      if (stageLevelController.value == 1) {
        setPositionBottomStream!(-500);
        setPositionTopStream!(0);
      }

      // stage getting the input
      if (stageLevelController.value != 1) {
        log.v("App is listening");
        start();
      }
    });
  }

  Future _speak(String text) async {
    await flutterTts.speak(text);
  }

  void onAiMoveCompleted() {
    // stage 2 started
    setstageLevelStream!(2);
    log.v({"stage": stageLevelController.value, "level": "get name"});

    Timer(Duration(milliseconds: 1500), () {
      _speak(MessageText.ask_Name);
    });
  }

  void initlizePlugins() {
    log.v("Initializing voice and mic");
    _setVoice();
    activateSpeechRecognizer();
  }

  void init(moveToHome) async {
    moveNext = moveToHome;
    log.v("App has been started");
    setPositionBottomStream!(100);
    setPositionTopStream!(100);

    initlizePlugins();

    try {
      final data = await db.collection('names').doc("n1").get();
      if (data!.isNotEmpty) {
        log.v(data);
        setstageLevelStream!(3);
      }
    } catch (e) {}

    Timer(Duration(seconds: 5), () {
      setTitleTextStream!("");
      log.v({"stage": stageLevelController.value, "level": "Welcome message"});
      _speak(MessageText.welcome_Message);
    });

    stageLevelController.listen((value) {
      if (value == 4) {
        dispose();
      }
    });
  }

  void dispose() {
    speakSentenceController.close();
    stageLevelController.close();
    speechStatusController.close();
    nameController.close();
    titleTextController.close();
    voiceAnimationController.close();
    positionTopController.cast();
    positionBottomController.close();
  }
}
