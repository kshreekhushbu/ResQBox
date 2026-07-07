// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:vivent/Utils/image_list.dart';

// Future<String> addTextToImage(
//   String text,
//   double textX,
//   double textY,
// ) async {
//   // Load the image
//   ByteData? imageData = await rootBundle.load(Images.viventLogo);
//   if (imageData == null) return ''; // Return empty string if image data is null

//   Uint8List bytes = Uint8List.view(imageData.buffer);

//   // Create an Image object from bytes
//   ui.Image img = await decodeImageFromList(bytes);

//   // Create a PictureRecorder and Canvas to draw on
//   ui.PictureRecorder recorder = ui.PictureRecorder();
//   Canvas canvas = Canvas(recorder);

//   // Draw the image onto the canvas
//   canvas.drawImage(img, Offset.zero, Paint());

//   // Define text style
//   TextStyle textStyle = const TextStyle(
//     fontSize: 30,
//     fontWeight: FontWeight.bold,
//     color: Colors.white,
//   );

//   // Create a ParagraphBuilder to format text
//   ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
//     ui.ParagraphStyle(
//       textAlign: TextAlign.center,
//       fontSize: 30,
//     ),
//   )
//     ..pushStyle(ui.TextStyle(color: textStyle.color))
//     ..addText(text);

//   // Create a Paragraph object from the builder
//   ui.Paragraph paragraph = paragraphBuilder.build();

//   // Layout the paragraph
//   paragraph.layout(ui.ParagraphConstraints(width: img.width.toDouble()));

//   // Draw text onto the canvas
//   canvas.drawParagraph(paragraph, Offset(textX, textY));

//   // Convert the canvas to an Image
//   ui.Image finalImage =
//       await recorder.endRecording().toImage(img.width, img.height);

//   // Convert the Image to bytes
//   ByteData? byteData =
//       await finalImage.toByteData(format: ui.ImageByteFormat.png);
//   if (byteData == null) return '';

//   Uint8List resultBytes = byteData.buffer.asUint8List();

//   // Save the resulting image
//   Directory? dir = await getDownloadsDirectory();
//   // String dir = (await getTemporaryDirectory()).path;
//   String imagePath = '${dir?.path}/result_image.png';
//   File(imagePath).writeAsBytesSync(resultBytes);

//   return imagePath; // Return the valid file path
// }
