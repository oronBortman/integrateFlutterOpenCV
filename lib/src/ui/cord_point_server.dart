import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_detector/src/ui/constants.dart';
import 'package:http/http.dart';

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

Future<String> fetchNotesInfoByPathOfFrame(String framePath) async {
  print("B1");
  final Uri uri = Uri.parse(FETCH_CHORD_NOTES_BY_FRAME_URL);
  print("B2");
  final MultipartRequest request = MultipartRequest('POST', uri);
  print("B3");
  request.files.add(await MultipartFile.fromPath('image', framePath));
  print("B4");
  final StreamedResponse response = await request.send();
  sleep(Duration(seconds:3));
  print("B5");
  final responseBytes = await response.stream.toBytes();
  print("notesInfo:" + utf8.decode(responseBytes));
  return utf8.decode(responseBytes);
/*
  print("B1");
  final Uri uri = Uri.parse(HELLO_WORLD_URL);
  print("B2");
  final MultipartRequest request = MultipartRequest('GET', uri);
  print("B3");
  //request.files.add(await MultipartFile.fromPath('image', framePath));
  print("B4");
  final StreamedResponse response = await request.send();
  //sleep(Duration(seconds:3));
  print("B5");
  final responseBytes = await response.stream.toBytes();
  print("notesInfo:" + utf8.decode(responseBytes));
  return utf8.decode(responseBytes);*/
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
  final List<Point> listOfNotesCoordinates = convJsonToListOfNotesCoordinates(listOfNotesInfoStr);
  print("A3");
  return createNoteWidgetsByListOfPoints(listOfNotesCoordinates);
}
