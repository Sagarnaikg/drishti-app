import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:drishti/resources/colors.dart';
import 'package:drishti/resources/font_weights.dart';
import 'package:drishti/screens/home/bloc.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:shimmer/shimmer.dart';

class CameraHome extends StatefulWidget {
  CameraHome({Key? key, required this.cameras}) : super(key: key);
  List<CameraDescription> cameras;
  @override
  State<CameraHome> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> {
  Bloc bloc = Bloc();

  @override
  void initState() {
    super.initState();

    bloc.init(widget.cameras);
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return StreamBuilder<bool>(
      stream: bloc.cameraInitCheckerStream,
      builder: (context, snapshot) {
        bool state = snapshot.data ?? false;

        if (state) {
          return Scaffold(
            body: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.maxFinite,
                  height: double.maxFinite,
                  child: CameraPreview(bloc.controller),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  width: double.infinity,
                  height: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 40,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 100),
                          width: 70,
                          height: 100,
                          child: const FlareActor("assets/animation/ai.flr",
                              alignment: Alignment.center,
                              fit: BoxFit.scaleDown,
                              animation: "Aura"),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        flex: 60,
                        child: StreamBuilder<String>(
                          stream: bloc.apiImageTextStream,
                          builder: (context, content) {
                            String text = content.data ?? "";

                            if (text != "") {
                              return Container(
                                width: double.infinity,
                                color: Color(0xff705FC5),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.medium,
                                    color: Colors.white,
                                    height: 1.5,
                                    fontSize: 20,
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey.shade500,
                                  highlightColor: Colors.grey.shade200,
                                  enabled: true,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            color: Colors.white60,
                                          ),
                                          width: double.infinity,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            color: Colors.white60,
                                          ),
                                          width: double.infinity,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            color: Colors.white60,
                                          ),
                                          width: width / 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onLongPress: () => {bloc.removeName()},
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: AppColor.COLOR_705FC5,
                        ),
                        padding: EdgeInsets.all(5),
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StreamBuilder<int>(
                                stream: bloc.imageCountStream,
                                builder: (context, snapshot) {
                                  int count = snapshot.data ?? 0;
                                  return Text(
                                    count.toString(),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: AppFontWeight.semiBold),
                                  );
                                }),
                            SizedBox(width: 5),
                            Icon(
                              Icons.photo,
                              color: Colors.white,
                              size: 20,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                StreamBuilder<bool>(
                    stream: bloc.micStatusStream,
                    builder: (context, snapshot) {
                      bool status = snapshot.data ?? false;
                      return Container(
                        width: double.infinity,
                        height: 5,
                        color: status ? Colors.green : Colors.red,
                      );
                    }),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(
                  height: 15,
                ),
                Text("Seeting up cameras...")
              ],
            )),
          );
        }
      },
    );
  }
}
