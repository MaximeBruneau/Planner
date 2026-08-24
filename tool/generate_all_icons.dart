// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final iconFile = File('assets/app_icon.png');
  if (!iconFile.existsSync()) {
    print('assets/app_icon.png not found!');
    exit(1);
  }

  final bytes = iconFile.readAsBytesSync();
  final source = img.decodeImage(bytes);
  if (source == null) {
    print('Failed to decode assets/app_icon.png');
    exit(1);
  }

  print('Source image loaded: ${source.width}x${source.height}');

  // 1. iOS AppIcon set
  final iosTargets = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-50x50@1x.png': 50,
    'Icon-App-50x50@2x.png': 100,
    'Icon-App-57x57@1x.png': 57,
    'Icon-App-57x57@2x.png': 114,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-72x72@1x.png': 72,
    'Icon-App-72x72@2x.png': 144,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!iosDir.existsSync()) iosDir.createSync(recursive: true);

  for (final entry in iosTargets.entries) {
    final resized = img.copyResize(source, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    final outFile = File('${iosDir.path}/${entry.key}');
    outFile.writeAsBytesSync(img.encodePng(resized));
    print('Generated iOS: ${entry.key} (${entry.value}x${entry.value})');
  }

  // 2. Android standard launcher icons
  final androidMipmaps = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  for (final entry in androidMipmaps.entries) {
    final file = File(entry.key);
    file.parent.createSync(recursive: true);
    final resized = img.copyResize(source, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated Android mipmap: ${entry.key}');
  }

  // 3. Android adaptive foregrounds
  final androidForegrounds = {
    'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png': 108,
    'android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png': 162,
    'android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png': 216,
    'android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png': 324,
    'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png': 432,
  };

  for (final entry in androidForegrounds.entries) {
    final file = File(entry.key);
    file.parent.createSync(recursive: true);
    final resized = img.copyResize(source, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated Android foreground: ${entry.key}');
  }

  // 4. Web icons
  final webTargets = {
    'web/favicon.png': 32,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
  };

  for (final entry in webTargets.entries) {
    final file = File(entry.key);
    file.parent.createSync(recursive: true);
    final resized = img.copyResize(source, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated Web: ${entry.key}');
  }

  print('\nSUCCESS! All iOS, Android, and Web icons completely rewritten from green bush asset.');
}
