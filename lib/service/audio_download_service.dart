import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioDownloadService {
  final Dio _dio = Dio();

  // Stream controller for download progress
  final StreamController<DownloadProgress> _downloadProgressController =
      StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get downloadProgressStream =>
      _downloadProgressController.stream;

  AudioDownloadService() {
    _init();
  }

  void _init() {}

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
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
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
