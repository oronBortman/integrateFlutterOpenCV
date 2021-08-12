import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_detector/src/bloc/cameras/cameras_bloc.dart';
import 'package:flutter_detector/src/bloc/detector/detector_bloc.dart';
import 'package:flutter_detector/src/bloc/lifecycle/lifecycle_bloc.dart';
import 'package:flutter_detector/src/ui/detector_component.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_detector/src/ui/cord_point.dart';

List<Widget> listOfCordPointWidgets = [];

class DetectorWidget extends StatefulWidget {
  @override
  State<DetectorWidget> createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget> {
  CameraController controller;
  Queue<String> imageCache;
  String dirPath;
  Size imageSize;


  @override
  void initState() {
    super.initState();
    imageCache = ListQueue();
    context.bloc<DetectorBloc>().add(InitialiseDetectorEvent());
    initDirectory();
  }

  @override
  Widget build(BuildContext context) => BlocListener<CamerasBloc, CamerasState>(
        listenWhen: (_, state) => state.cameras.isNotEmpty,
        listener: (_, state) => onNewCameraSelected(state.cameras[0]),
        child: BlocListener<LifecycleBloc, LifecycleState>(
          listenWhen: (_, state) => state.isActive,
          listener: (_, __) => startCapturing(),
          child: BlocListener<DetectorBloc, DetectorState>(
            listenWhen: (_, state) => state is DetectedObjectsState && context.bloc<LifecycleBloc>().state.isActive,
            listener: (_, __) {
              startCapturing();
            },
              child: BlocBuilder<CamerasBloc, CamerasState>(
                builder: (_, camState) {
                  if (camState is NoCamerasAvailableState) {
                    return const Center(
                      child: Text('No available cameras found'),
                    );
                  }
                  return camState is CamerasAvailableState ? cameraContent : progressWidget;
                },
              ),
            ),
          ),
      );

  Widget get progressWidget => const Center(
        child: SizedBox(
          width: 48.0,
          height: 48.0,
          child: CircularProgressIndicator(),
        ),
      );


  Widget get cameraContent {
    if (controller == null || !controller.value.isInitialized) {
      return progressWidget;
    } else {
      // for Android. Cant be received from MediaQuery because of Scaffold.
      // for iOS - need to check it;
      const statusBar = 24.0;
      final screenH = max(size.height, size.width) - APP_BAR_HEIGHT - statusBar;
      final screenW = min(size.height, size.width);
      final preview = controller.value.previewSize;
      final previewH = max(preview.height, preview.width) - APP_BAR_HEIGHT - statusBar;
      final previewW = min(preview.height, preview.width);
      final screenRatio = screenH / screenW;
      final previewRatio = previewH / previewW;
      final maxHeight = screenRatio > previewRatio ? screenH : screenW / previewW * previewH;
      final maxWidth = screenRatio > previewRatio ? screenH / previewH * previewW : screenW;

      return Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          CameraPreview(controller),
          ...listOfCordPointWidgets,
        ],
      );
    }
  }

  void showMessage(String title, String message) => Flushbar<dynamic>(
        title: title,
        message: message,
        borderRadius: 12.0,
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(8.0),
        duration: const Duration(seconds: 3),
        animationDuration: const Duration(seconds: 0),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    controller = CameraController(
      cameraDescription,
      ResolutionPreset.max,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (controller.value.hasError) {
        showMessage('Camera error', controller.value.errorDescription);
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    } finally {
      if (mounted) {
        startCapturing();
      }
    }
  }

  void startCapturing() {
    if (context.bloc<DetectorBloc>().state is DetectorLoadingErrorState) {
      showMessage('TFLite error', 'Model not loaded');
      return;
    }
    fetchFrame.then(
      (filePath) async {
        if (filePath?.isEmpty ?? true) {
          return;
        }
        try {
          createNoteWidgetsByFrame(filePath).then((List<Widget> result){
            setState(() {
              listOfCordPointWidgets = result;
            });
          });
          context.bloc<DetectorBloc>().add(DetectObjectsEvent(filePath));
        } catch (e) {
          print(e);
        }
      },
    );
  }



  Future<String> get fetchFrame async {
    if (!mounted || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return null;
    }

    try {
      clearCache();
      final imagePath = '$dirPath/${timestamp()}.jpg';
      await controller?.takePicture(imagePath);
      imageCache.add(imagePath);
    } catch (e) {
      print(e.toString());
      return null;
    }
    return imageCache.last;
  }

  void clearCache() {
    if (imageCache.length >= 10) {
      Isolate.spawn(removeFile, UrlParam(imageCache.removeFirst(), ReceivePort().sendPort));
    }
  }

  Size get size => MediaQuery.of(context).size;

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showMessage('Error: ${e.code}', e.description);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> initDirectory() async {
    dirPath = await getApplicationDocumentsDirectory().then((io.Directory dir) => '${dir.path}/Pictures');
    final dir = io.Directory(dirPath);
    if (io.Directory(dirPath).existsSync()) {
      dir.deleteSync(recursive: true);
    }
    io.Directory('$dirPath/cropp').createSync(recursive: true);
  }
}

void logError(String code, String message) => print('Error: $code\nError Message: $message');

class UrlParam {
  UrlParam(this.path, this.sendPort);

  final String path;
  final SendPort sendPort;
}

Future<void> removeFile(UrlParam param) async {
  final file = io.File(param.path);
  if (file.existsSync()) {
    await file.delete();
  }
}