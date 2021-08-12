import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_detector/src/models/decode_params.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image/image.dart' as image;
import 'package:tflite/tflite.dart';

const String WIDTH_KEY = 'EXIF ExifImageWidth';
const String HEIGHT_KEY = 'EXIF ExifImageLength';
const String ROTATION_KEY = 'Image Orientation';

typedef DetectionCallback = void Function(List<dynamic> list);
typedef CutOffCallback = void Function();

/// Class with access to model loading, label detection, etc.
class Detector {
  factory Detector() => _instance;

  Detector._internal();

  static final Detector _instance = Detector._internal();

  /// Initialize detector with provided models
  Future<String> initializeDetector({String model, String labels}) async => Tflite.loadModel(
        model: model ?? 'assets/ssd_mobilenet.tflite',
        labels: labels ?? 'assets/ssd_mobilenet.txt',
        numThreads: 2,
      );

  /// Release memory
  Future<dynamic> release() => Tflite.close();

  /// Detect objects on image
  Future<List<dynamic>> detectObjects(String imagePath) async {
    final int startTime = DateTime.now().millisecondsSinceEpoch;

    return FlutterExifRotation.rotateImage(path: imagePath)
        .then((file) => Tflite.detectObjectOnImage(
              path: file.path,
              threshold: 0.3,
            ))
        .then<List<dynamic>>(
      (List<dynamic> recognitions) {
        final int endTime = DateTime.now().millisecondsSinceEpoch;
        debugPrint('Detection took ${endTime - startTime}');
        return recognitions;
      },
    );
  }

  /// Image Exif information reader
  static Future<Map<String, IfdTag>> getExif(String imagePath) => _getBytes(imagePath).then(readExifFromBytes);

  /// Image Exif size getter
  static Future<Size> getImageSize(String imagePath) => _getBytes(imagePath).then(readExifFromBytes).then((data) {
        Size size;
        if (data != null && data.isNotEmpty) {
          final double w = double.tryParse(data[WIDTH_KEY].toString());
          final double h = double.tryParse(data[HEIGHT_KEY].toString());
          size = Size(min(w, h), max(w, h));
        }
        return size;
      });

  /// Get list of image bytes
  static Future<Uint8List> _getBytes(String imagePath) => io.File(imagePath).readAsBytes();

  static Future<void> _printExifOfPath(String path) => _getBytes(path).then(_printExifOfBytes);

  static Future<void> _printExifOfBytes(Uint8List bytes) async {
    final Map<String, IfdTag> data = await readExifFromBytes(bytes);

    if (data == null || data.isEmpty) {
      debugPrint('No EXIF information found\n');
      return;
    }

    if (data.containsKey('JPEGThumbnail')) {
      debugPrint('File has JPEG thumbnail');
      data.remove('JPEGThumbnail');
    }
    if (data.containsKey('TIFFThumbnail')) {
      debugPrint('File has TIFF thumbnail');
      data.remove('TIFFThumbnail');
    }

    for (final key in data.keys) {
      debugPrint('$key (${data[key].tagType}): ${data[key]}');
    }
  }
}
