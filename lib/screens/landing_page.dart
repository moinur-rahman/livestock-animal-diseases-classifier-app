import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class LandingPage extends StatefulWidget {
  static const String routeName = '/landing_page';
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LandingPageState();
  }
}

class _LandingPageState extends State<LandingPage> {
  File? _image;
  final ImagePicker _imagePicker = ImagePicker();
  String? diseaseName;
  double? confidenceLevel;

  Future<void> _selectImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // call image cropper

      File? croppedFile = await ImageCropper().cropImage(
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
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Crop Image',
        ),
      );
      if (croppedFile != null) {
        setState(() {
          _image = croppedFile;
        });
      }
    }
  }

  Future<void> _submitImage() async {
    if (_image != null) {
      String url =
          "http://10.0.3.2:8000/classify/"; // Replace with your API endpoint
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files
          .add(await http.MultipartFile.fromPath('image', _image!.path));

      var response = await request.send();

      print(response);
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var decodedData = jsonDecode(responseData);
        setState(() {
          diseaseName = decodedData['class_name'];
          confidenceLevel =
              double.parse(decodedData['confidence'].toStringAsFixed(2)) * 100;
        });
        print('Image uploaded successfully');
        _showResultDialog();
      } else {
        // Error occurred while uploading image
        print('Image upload failed');
      }
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Disease Detection Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Disease detected:',
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$diseaseName',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Confidence level:',
              ),
              Text(
                '$confidenceLevel %',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: height * 0.03,
          ),
        ),
        toolbarHeight: height * 0.04,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(
                    _image!,
                    width: width * 0.7,
                    height: height * 0.5,
                    fit: BoxFit.contain,
                  )
                : Text(
                    'No image selected.\n Crop image to disease area for enhanced results.',
                    textAlign: TextAlign.center,
                  ),
            SizedBox(height: height * 0.02),
            ElevatedButton(
              onPressed: _selectImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: height * 0.02),
            ElevatedButton(
              onPressed: _submitImage,
              child: Text('Submit Image'),
            ),
          ],
        ),
      ),
    );
  }
}
