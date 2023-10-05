import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const OCRPage());
}

/// CameraApp is the Main Application.
class OCRPage extends StatefulWidget {
  /// Default Constructor
  const OCRPage({super.key});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  late CameraController controller;
  ValueNotifier<int> selectedItemValue = ValueNotifier(0);
  File? _image;
  ImagePicker _imagePicker = ImagePicker();
  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: CameraPreview(controller)),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.8),
                        ])),
                    height: 200,
                    child: Column(
                      children: [scrollView(), bottomBar()],
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget bottomBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 70, right: 70),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _getImageFromGallery(ImageSource.gallery),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_search_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          cameraButton,
          const SizedBox(
            height: 45,
            width: 45,
          )
        ],
      ),
    );
  }

  Widget get cameraButton => GestureDetector(
        onTap: () async {
          if (!controller.value.isInitialized) {
            return;
          }
          if (controller.value.isTakingPicture) {
            return;
          }
          try {
            XFile pickedFile = await controller.takePicture();
            CroppedFile? croppedFile = await ImageCropper().cropImage(
              sourcePath: pickedFile.path,
              aspectRatioPresets: Platform.isAndroid
                  ? [
                      CropAspectRatioPreset.square,
                      CropAspectRatioPreset.ratio3x2,
                      CropAspectRatioPreset.original,
                      CropAspectRatioPreset.ratio4x3,
                      CropAspectRatioPreset.ratio16x9
                    ]
                  : [
                      CropAspectRatioPreset.original,
                      CropAspectRatioPreset.square,
                      CropAspectRatioPreset.ratio3x2,
                      CropAspectRatioPreset.ratio4x3,
                      CropAspectRatioPreset.ratio5x3,
                      CropAspectRatioPreset.ratio5x4,
                      CropAspectRatioPreset.ratio7x5,
                      CropAspectRatioPreset.ratio16x9
                    ],
              uiSettings: [
                AndroidUiSettings(
                    toolbarTitle: 'Kırpıcı',
                    toolbarColor: Colors.deepOrange,
                    toolbarWidgetColor: Colors.white,
                    initAspectRatio: CropAspectRatioPreset.original,
                    lockAspectRatio: false),
                IOSUiSettings(
                  title: 'Kırpıcı',
                  // doneButtonTitle: "done".tr,
                  // cancelButtonTitle: "cancel".tr,
                ),
              ],
            );

            if (croppedFile != null) {
              File file = File(croppedFile.path);
              _processPickedFile(file);
            }
          } on CameraException catch (e) {
            debugPrint("Error occured while taking picture : $e");
            return;
          }
        },
        child: Container(
          height: 70,
          width: 70,
          decoration:
              BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  color: Colors.white,
                  shape: BoxShape.circle),
            ),
          ),
        ),
      );

  Future _getImageFromGallery(ImageSource source) async {
    setState(() {
      _image = null;
    });
    final pickedFile = await _imagePicker.pickImage(
        source: source, preferredCameraDevice: CameraDevice.rear);
    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Kırpıcı',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Kırpıcı',
            // doneButtonTitle: "done".tr,
            // cancelButtonTitle: "cancel".tr,
          ),
        ],
      );

      if (croppedFile != null) {
        File file = File(croppedFile.path);
        _processPickedFile(file);
      }
    }
  }

  Future _processPickedFile(File? pickedFile) async {
    String app_id = "xxx";
    String app_key = "xxx";
    List<int> image_bytes = pickedFile!.readAsBytesSync();
    String image_data = base64Encode(image_bytes);
    print(image_data.characters);
    Map<String, dynamic> params = {
      "src": "data:image/jpg;base64,$image_data",
      "data_options": {"include_asciimath": true, "include_latex": true}
    };

    Map<String, String> headers = {
      "app_id": app_id,
      "app_key": app_key,
      "Content-type": "application/json"
    };
    var response = await http.post(
      Uri.parse("https://api.mathpix.com/v3/text"),
      body: jsonEncode(params),
      headers: headers,
    );
    var data = jsonDecode(response.body);
    print(convertToLatex(data['text']));
  }

  ///Network

//  void _processPickedFile() async {
//     var url = Uri.parse('https://api.mathpix.com/v3/text');

//     String app_id = "xxx";
//     String app_key =
//         "xxx";
//     var image_url =
//         'https://mathpix-ocr-examples.s3.amazonaws.com/cases_hw.jpg';
//     var format = 'latex_simplified';
//     var headers = {
//       'app_id': app_id,
//       'app_key': app_key,
//       'Content-type': 'application/json'
//     };
//     var body = jsonEncode({
//       "src": image_url,
//       // 'formats': [format],
//       'data_options': {
//         'include_latex': true,
//         'include_asciimath': true,
//         'include_mathml': true
//       }
//     });

//     var response = await http.post(url, headers: headers, body: body);

//     if (response.statusCode == 200) {
//       // Parse the response body as JSON
//       var data = jsonDecode(response.body);

//       print(data);
//     } else {
//       // Print the error message
//       print('Request failed with status: ${response.statusCode}.');
//     }
//   }

  String convertToLatex(String mathpixCode) {
    String latexCode =
        mathpixCode.replaceAll("\\(", "\$\$").replaceAll("\\)", "\$\$");
    return latexCode;
  }

  Widget scrollView() {
    List<Widget> _buildList() {
      return [
        RotatedBox(
          quarterTurns: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
                child: ValueListenableBuilder(
              valueListenable: selectedItemValue,
              builder: (context, value, child) => Text(
                "TEXT BASED",
                style: TextStyle(
                    fontSize: 16.0,
                    color: value == 0 ? Colors.white : Colors.grey),
              ),
            )),
          ),
        ),
        RotatedBox(
          quarterTurns: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
                child: ValueListenableBuilder(
              valueListenable: selectedItemValue,
              builder: (context, value, child) => Text(
                "MATH BASED",
                style: TextStyle(
                    fontSize: 16.0,
                    color: value == 1 ? Colors.white : Colors.grey),
              ),
            )),
          ),
        ),
      ];
    }

    return Center(
      child: SizedBox(
        height: 70,
        child: RotatedBox(
          quarterTurns: -1,
          child: ListWheelScrollView(
            onSelectedItemChanged: (value) => selectedItemValue.value = value,
            itemExtent: 140,
            diameterRatio: 1.5,
            useMagnifier: false,
            physics: const FixedExtentScrollPhysics(), // Kaydırma fizikleri
            offAxisFraction: 0,
            children: _buildList(),
          ),
        ),
      ),
    );
  }
}
