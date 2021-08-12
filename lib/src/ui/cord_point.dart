import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_detector/src/ui/constants.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

Widget createNoteWidget(Point point)
{
  return Positioned(
    left: point.x.toDouble() ,
    top: point.y.toDouble() ,
    child: Container(
      width: WIDTH_NOTE,
      height: HEIGHT_NOTE,
      decoration: const BoxDecoration(
        shape: NOTE_SHAPE,
        color: COLOR_NOTE,
      ),
    ),
  );
}

List<Point> createPointsListFromJson(dynamic listOfNotesCoordinatesJson, int numOfNotes)
{
  final List<Point> listOfCordNotesCoordinates = <Point>[];

  for(int i=0; i< numOfNotes; i++){
    final dynamic point = listOfNotesCoordinatesJson[i];
    final int x = convertDynamicToInt(point[X_JSON_KEY]);
    final int y = convertDynamicToInt(point[Y_JSON_KEY]);
    listOfCordNotesCoordinates.add(Point(x,y));
  }

  return listOfCordNotesCoordinates;
}

int convertDynamicToInt(dynamic jsonVal)
{
  return int.parse(jsonVal.toString());
}

List<Point> convJsonToListOfNotesCoordinates(String listOfNotesInfoStr)
{
  final dynamic listOfNotesInfoJson = json.decode(listOfNotesInfoStr);

  final dynamic listOfNotesCoordinatesJson = listOfNotesInfoJson[NOTES_COORDINAES_JSON_KEY];
  final int numOfNotes = convertDynamicToInt(listOfNotesInfoJson[NUM_NOTES_JSON_KEY]);

  return createPointsListFromJson(listOfNotesCoordinatesJson, numOfNotes);
}

Future<String> getPathToSaveFrame()
async {
  String dirPath = await getApplicationDocumentsDirectory().then((Directory dir) => dir.path);
  print("DIR!!: " + dirPath);
  List<String> folders = dirPath.split("/");
  String newPath="";

  for(int i=1; i < folders.length; i++)
  {
    String folder = folders[i];
    if(folder != "app_flutter") {
      newPath += "/" + folder;
    }
    else {
      break;
    }
  }
  newPath += "/files/chaquopy/AssetFinder/app/c.jpeg";
  print("CCCCC: " + newPath);

  return newPath;

}

Future<String> fetchNotesInfoByPathOfFrame(String framePath) async {

  String path = await getPathToSaveFrame();
  File(framePath).copy(path);
  var outputMap = await Chaquopy.executeCode("script.py");
  print("YYYYY");
  print(outputMap['textOutputOrError'].toString());
  return outputMap['textOutputOrError'].toString();
}

List<Widget> createNoteWidgetsByListOfPoints(List<Point> listOfNotesCoordinates)
{
  final List<Widget> listOfWidgets = [];
  for(final Point point in listOfNotesCoordinates)
  {
    listOfWidgets.add(createNoteWidget(point));
  }
  return listOfWidgets;
}

Future<List<Widget>> createNoteWidgetsByFrame(String framePath)
async {
  print("A1");
  final String listOfNotesInfoStr = await fetchNotesInfoByPathOfFrame(framePath);
  print("A2");
  //bad:
  //{"notes_coordinates": [{"x": "11", "y": "9"}, {"x": "23", "y": "0"}, {"x": "27", "y": "42"}], "numOfNotes": "3"}
  //good
  //{"notes_coordinates": [{"x": "13", "y": "39"}, {"x": "19", "y": "38"}, {"x": "37", "y": "27"}], "numOfNotes": "3"}
  //final String listOfNotesInfoStr = "{\"notes_coordinates\": [{\"x\": \"12\", \"y\": \"18\"}, {\"x\": \"47\", \"y\": \"29\"}, {\"x\": \"10\", \"y\": \"39\"}], \"numOfNotes\": \"3\"}";
  final List<Point> listOfNotesCoordinates = convJsonToListOfNotesCoordinates(listOfNotesInfoStr);
  print("A3");
  return createNoteWidgetsByListOfPoints(listOfNotesCoordinates);
}
