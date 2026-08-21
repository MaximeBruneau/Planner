// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputBytes = File('d:/Github/myDairy/assets/app_icon.png').readAsBytesSync();
  final original = img.decodeImage(inputBytes);
  
  if (original == null) {
    print('Failed to decode image');
    return;
  }

  // Create a 1024x1024 canvas
  const canvasSize = 1024;
  
  // Safe zone for adaptive icon is ~65-70% of canvas
  const targetDimension = 720;
  
  double scale;
  if (original.width > original.height) {
    scale = targetDimension / original.width;
  } else {
    scale = targetDimension / original.height;
  }
  
  final newW = (original.width * scale).round();
  final newH = (original.height * scale).round();
  
  final resized = img.copyResize(original, width: newW, height: newH, interpolation: img.Interpolation.cubic);
  
  // Create solid background or transparent background
  // For standard icon (iOS/legacy Android): Soft pleasant background or white
  final fullCanvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  img.fill(fullCanvas, color: img.ColorRgba8(255, 255, 255, 255)); // Crisp clean white background
  
  // For adaptive icon foreground (transparent)
  final fgCanvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  img.fill(fgCanvas, color: img.ColorRgba8(0, 0, 0, 0));
  
  final posX = ((canvasSize - newW) / 2).round();
  final posY = ((canvasSize - newH) / 2).round();
  
  img.compositeImage(fullCanvas, resized, dstX: posX, dstY: posY);
  img.compositeImage(fgCanvas, resized, dstX: posX, dstY: posY);
  
  File('d:/Github/myDairy/assets/app_icon_full.png').writeAsBytesSync(img.encodePng(fullCanvas));
  File('d:/Github/myDairy/assets/app_icon_fg.png').writeAsBytesSync(img.encodePng(fgCanvas));
  
  print('Successfully processed icons!');
}
