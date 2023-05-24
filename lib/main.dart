import 'package:body_detection/body_detection.dart';
import 'package:body_detection/models/image_result.dart';
import 'package:body_detection/models/pose.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pushup_counter/generated/assets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override
  Widget build(BuildContext context) {
    // var width=MediaQuery.of(context).size.width;
    // var height=MediaQuery.of(context).size.height;
    return MaterialApp(
      home: const MainScreen(),
      theme: ThemeData(
        primaryColor:const Color(0xff282A3A) ,
        scaffoldBackgroundColor: const Color(0xff282A3A),
        primarySwatch: createMaterialColor(const Color(0xff282A3A)),
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),
        primaryTextTheme:
        GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),
      ),
    );
  }
  MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((strength) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    });
    return MaterialColor(color.value, swatch);
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double wristY = 0.0;
  double shoulderY = 0.0;
  double pushUpCount = 0;
  Pose? _detectedPose;
  bool up = false;
  var _cameraImage;
  bool down = true;

  Future<void> _startCameraStream() async {
    final request = await Permission.camera.request();
    if (request.isGranted) {
      await BodyDetection.startCameraStream(
        onFrameAvailable: _handleCameraImage,
        onPoseAvailable: (pose) {
          _handlePose(pose);
          if (_detectedPose != null) {
            if(_detectedPose!.landmarks.isNotEmpty){
              if (down) {
                if (_detectedPose!.landmarks[11].position.y ==
                    _detectedPose!.landmarks[13].position.y ||
                    _detectedPose!.landmarks[11].position.y >
                        _detectedPose!.landmarks[13].position.y) {
                  pushUpCount = pushUpCount + 0.5;
                  setState(() {
                    down = !down;
                    up = true;
                  });
                }
              } else if (up) {
                if (_detectedPose!.landmarks[11].position.y <
                    _detectedPose!.landmarks[13].position.y) {
                  pushUpCount = pushUpCount + 0.5;
                  setState(() {
                    up = !up;
                    down = true;
                  });
                }
              }
            }
          }
        },
        onMaskAvailable: (mask) {},
      );
    }
  }


  void _handleCameraImage(ImageResult result) {
    if (!mounted) return;

    PaintingBinding.instance?.imageCache?.clear();
    PaintingBinding.instance?.imageCache?.clearLiveImages();

    setState(() {
      _cameraImage = result.bytes;
    });
  }

  void _handlePose(Pose? pose) {
    if (!mounted) return;

    setState(() {
      _detectedPose = pose;
    });
  }

  Future<void> onStart() async {
    await BodyDetection.switchCamera(LensFacing.back);
    await _startCameraStream();
    await BodyDetection.enablePoseDetection();
  }

  @override
  void initState() {
    onStart();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    var width=MediaQuery.of(context).size.width;
    var height=MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 60,),
                Transform.rotate(
                  angle: 360/10,
                  child: Transform.scale(
                      scale: 1.7,
                      child: Image.asset(Assets.imagesBlob,)),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: width * 0.04,horizontal: width * 0.04),
            child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("PushUp Counter",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: width * 0.07),),
                      Image.asset(Assets.imagesPushup,width: width * 0.2,),
                    ],
                  ),
                  const Divider(color: Colors.white,thickness: 1.2,),
                  SizedBox(height: width * 0.04,),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87)
                    ),
                    width: width * 0.8,
                    height: width * 1.2,
                    child: _cameraImage != null
                        ? Image.memory(
                            _cameraImage,
                            gaplessPlayback: true,
                            fit: BoxFit.fill,
                            width: width,
                            height: height,
                          )
                        : Container(),
                  ),
                  SizedBox(height: width * 0.04,),
                  const Divider(color: Colors.white,thickness: 1.2,),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text("Count Number",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: width * 0.07),),
                          Text(pushUpCount.toInt().toString(),style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: width * 0.07),),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
