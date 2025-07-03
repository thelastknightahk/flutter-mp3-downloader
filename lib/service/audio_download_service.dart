import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioDownloadService extends BaseAudioHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();

  // Stream controller for download progress
  final StreamController<DownloadProgress> _downloadProgressController =
      StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get downloadProgressStream =>
      _downloadProgressController.stream;

  AudioDownloadService() {
    _init();
  }

  void _init() {
    // Listen to audio player state changes
    _audioPlayer.playbackEventStream.listen((event) {
      final playing = _audioPlayer.playing;
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState:
              const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_audioPlayer.processingState]!,
          playing: playing,
          updatePosition: _audioPlayer.position,
          bufferedPosition: _audioPlayer.bufferedPosition,
          speed: _audioPlayer.speed,
          queueIndex: 0,
        ),
      );
    });
  }

  Future<String?> downloadMp3(String url, {String? fileName}) async {
    try {
      // Request permissions
      await _requestPermissions();

      // Get download directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadPath = '${directory.path}/downloads';

      // Create directory if it doesn't exist
      await Directory(downloadPath).create(recursive: true);

      // Generate filename
      fileName ??= 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final filePath = '$downloadPath/$fileName';

      // Initialize progress
      _downloadProgressController.add(
        DownloadProgress(
          received: 0,
          total: 0,
          percentage: 0.0,
          speed: 0.0,
          status: DownloadStatus.downloading,
        ),
      );

      final DateTime startTime = DateTime.now();

      // Download file
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final percentage = (received / total * 100);
            final elapsed = DateTime.now().difference(startTime).inMilliseconds;
            final speed =
                elapsed > 0
                    ? (received / elapsed) * 1000
                    : 0.0; // bytes per second

            _downloadProgressController.add(
              DownloadProgress(
                received: received,
                total: total,
                percentage: percentage,
                speed: speed,
                status: DownloadStatus.downloading,
              ),
            );
          }
        },
      );

      // Download completed
      _downloadProgressController.add(
        DownloadProgress(
          received: 0,
          total: 0,
          percentage: 100.0,
          speed: 0.0,
          status: DownloadStatus.completed,
        ),
      );

      return filePath;
    } catch (e) {
      print('Download error: $e');
      _downloadProgressController.add(
        DownloadProgress(
          received: 0,
          total: 0,
          percentage: 0.0,
          speed: 0.0,
          status: DownloadStatus.failed,
        ),
      );
      return null;
    }
  }

  void dispose() {
    _downloadProgressController.close();
    _audioPlayer.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  @override
  Future<void> play() async {
    _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    _audioPlayer.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    _audioPlayer.seek(position);
  }

  Future<void> playFromFile(String filePath) async {
    try {
      await _audioPlayer.setFilePath(filePath);
      await play();
    } catch (e) {
      print('Error playing file: $e');
    }
  }

  Future<void> playFromUrl(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await play();
    } catch (e) {
      print('Error playing from URL: $e');
    }
  }
}

// Download progress model
class DownloadProgress {
  final int received;
  final int total;
  final double percentage;
  final double speed; // bytes per second
  final DownloadStatus status;

  DownloadProgress({
    required this.received,
    required this.total,
    required this.percentage,
    required this.speed,
    required this.status,
  });

  String get formattedSpeed {
    if (speed < 1024) {
      return '${speed.toStringAsFixed(1)} B/s';
    } else if (speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  String get formattedSize {
    final totalMB = total / (1024 * 1024);
    final receivedMB = received / (1024 * 1024);
    return '${receivedMB.toStringAsFixed(1)} MB / ${totalMB.toStringAsFixed(1)} MB';
  }
}

enum DownloadStatus { downloading, completed, failed, idle }
