import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'screens/audio_download_screen.dart';
import 'service/audio_download_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_downloader
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  // Initialize audio service
  final audioHandler = await AudioService.init(
    builder: () => AudioDownloadService(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.prime.audio_background_download.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(MyApp(audioHandler: audioHandler));
}

class MyApp extends StatelessWidget {
  final AudioHandler audioHandler;

  const MyApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MP3 Background Downloader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AudioDownloadScreen(audioHandler: audioHandler),
    );
  }
}
