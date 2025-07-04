import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'screens/audio_download_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_downloader
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MP3 Background Downloader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AudioDownloadScreen(),
    );
  }
}
