import 'package:drishti/resources/font_weights.dart';
import 'package:drishti/screens/home/screen.dart';
import 'package:drishti/screens/init/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:camera/camera.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({Key? key, required this.cameras}) : super(key: key);
  List<CameraDescription> cameras;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Bloc bloc = Bloc();

  @override
  void initState() {
    super.initState();

    // starting
    bloc.init(moveToHome);
  }

  void moveToHome() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CameraHome(
              cameras: widget.cameras,
            )));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
        body: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Center(
            child: StreamBuilder<String>(
                stream: bloc.nameStream,
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? "",
                    style: TextStyle(
                        fontSize: 38, fontWeight: AppFontWeight.semiBold),
                  );
                })),
        StreamBuilder<double>(
          stream: bloc.positionBottomController,
          builder: (context, bottom) {
            return StreamBuilder<double>(
                stream: bloc.positionTopStream,
                builder: (context, top) {
                  return AnimatedPositioned(
                    onEnd: bloc.onAiMoveCompleted,
                    curve: Curves.easeInOut,
                    duration: Duration(milliseconds: 1000),
                    top: top.data,
                    bottom: bottom.data,
                    child: StreamBuilder<bool>(
                        stream: bloc.voiceAnimationStream,
                        builder: (context, snapshot) {
                          bool state = snapshot.data ?? false;
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 100),
                            width: state ? 170 : 190,
                            height: state ? 170 : 190,
                            child: const FlareActor("assets/animation/ai.flr",
                                alignment: Alignment.center,
                                fit: BoxFit.contain,
                                animation: "Aura"),
                          );
                        }),
                  );
                });
          },
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: height / 3.5),
              StreamBuilder<String>(
                  stream: bloc.titleTextStream,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? "Drishti",
                      style: TextStyle(
                          fontSize: 28, fontWeight: AppFontWeight.semiBold),
                    );
                  }),
            ],
          ),
        ),
      ],
    ));
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}
