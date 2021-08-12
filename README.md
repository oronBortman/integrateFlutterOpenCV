# Integration between Flutter and OpenCV

The Application runs openCV on every frame and draw on the frame the notes of a chord.

## Flutter
- Preview the camera
- For every second:
  1. Take a frame
  2. Call Python script of image processing using chaquopy package of Flutter.
  3. Get from the script the coordinates of the notes of the chord in json format.
  4. Draw the coordinates on the revlant places on the preview of the camera.

## OpenCV
All the related files of openCV are at "integrateFlutterOpenCV/android/app/src/main/python".

'script.py':
  - Gets the frame from the local storage of the device
  - Run image processing with openCV to identify the coordinates of a certain chord of the guitar in the frame
   return json in the following format:
 
 ```
 {
     "notes_coordinates":[
      {
         "x":"1",
         "y":"2"
      },
      {
         "x":"20",
         "y":"30"
      },
      {
         "x":"50",
         "y":"10"
      }
    ],
    "numOfNotes":"3"
}
``` 
x = coordinate x of the note

y = coordinate y of the note

numOfNotes = The number of the notes of the chord
  

