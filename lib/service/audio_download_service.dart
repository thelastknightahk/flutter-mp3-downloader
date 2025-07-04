import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
class AudioDownloadService {
  // Stream controller for download progress
  final StreamController<DownloadProgress> _downloadProgressController =
      StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get downloadProgressStream =>
      _downloadProgressController.stream;

  // Port for receiving download updates
  final ReceivePort _port = ReceivePort();

  // Map to track download tasks
  final Map<String, String> _downloadTasks = {};

  AudioDownloadService() {
    _init();
  }

  void _init() {
    // Register callback for download updates
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );

    _port.listen((dynamic data) {
      final String id = data[0];
      final int status = data[1];
      final int progress = data[2];

      _handleDownloadUpdate(id, status, progress);
    });

    // Set up the callback
    FlutterDownloader.registerCallback(downloadCallback);
  }

  // Static callback function for download updates
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    send?.send([id, status, progress]);
  }

  void _handleDownloadUpdate(String taskId, int status, int progress) {
    final downloadStatus = _mapDownloadStatus(status);

    _downloadProgressController.add(
      DownloadProgress(
        received: progress,
        total: 100,
        percentage: progress.toDouble(),
        speed: 0.0, // flutter_downloader doesn't provide speed
        status: downloadStatus,
        taskId: taskId,
      ),
    );
  }

  DownloadStatus _mapDownloadStatus(int status) {
    // Based on flutter_downloader status codes:
    // 0: undefined, 1: enqueued, 2: running, 3: complete, 4: failed, 5: canceled, 6: paused
    switch (status) {
      case 2: // running
        return DownloadStatus.downloading;
      case 3: // complete
        return DownloadStatus.completed;
      case 4: // failed
        return DownloadStatus.failed;
      case 5: // canceled
        return DownloadStatus.failed;
      case 6: // paused
        return DownloadStatus.downloading;
      default:
        return DownloadStatus.idle;
    }
  }

  /// for internal save
  Future<String?> downloadMp3(String url, {String? fileName}) async {
    try {
      // Request permissions
      await _requestPermissions();

      // Get download directory - using internal storage only
      Directory directory = await getApplicationDocumentsDirectory();
      final downloadPath = '${directory.path}/downloads';

      // Create directory if it doesn't exist
      await Directory(downloadPath).create(recursive: true);

      // Generate filename
      fileName ??= 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

      // Initialize progress
      _downloadProgressController.add(
        DownloadProgress(
          received: 0,
          total: 100,
          percentage: 0.0,
          speed: 0.0,
          status: DownloadStatus.downloading,
        ),
      );

      // Start download
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: downloadPath,
        fileName: fileName,
        headers: {}, // Optional headers
        showNotification: false, // Disable notifications to avoid icon issues
        openFileFromNotification: false,
        saveInPublicStorage: false, // Set to false to avoid permission issues
      );

      if (taskId != null) {
        _downloadTasks[taskId] = fileName;

        // Wait for download completion
        await _waitForDownloadCompletion(taskId);

        final filePath = '$downloadPath/$fileName';
        return filePath;
      }

      return null;
    } catch (e) {
      print('Download error: $e');
      _downloadProgressController.add(
        DownloadProgress(
          received: 0,
          total: 100,
          percentage: 0.0,
          speed: 0.0,
          status: DownloadStatus.failed,
        ),
      );
      return null;
    }
  }

  /// for external save
  //   Future<String?> downloadMp3(String url, {String? fileName}) async {
  //   try {
  //     // Request permissions
  //     await _requestPermissions();

  //     // Get download directory
  //     Directory directory;
  //     if (Platform.isAndroid) {
  //       directory =
  //           await getExternalStorageDirectory() ??
  //           await getApplicationDocumentsDirectory();
  //     } else {
  //       directory = await getApplicationDocumentsDirectory();
  //     }

  //     final downloadPath = '${directory.path}/downloads';

  //     // Create directory if it doesn't exist
  //     await Directory(downloadPath).create(recursive: true);

  //     // Generate filename
  //     fileName ??= 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

  //     // Initialize progress
  //     _downloadProgressController.add(
  //       DownloadProgress(
  //         received: 0,
  //         total: 100,
  //         percentage: 0.0,
  //         speed: 0.0,
  //         status: DownloadStatus.downloading,
  //       ),
  //     );

  //     // Start download
  //     final taskId = await FlutterDownloader.enqueue(
  //       url: url,
  //       savedDir: downloadPath,
  //       fileName: fileName,
  //       headers: {}, // Optional headers
  //       showNotification: true, // Disable notifications to avoid icon issues
  //       openFileFromNotification: true,
  //       saveInPublicStorage: true, // Set to false to avoid permission issues
  //     );

  //     if (taskId != null) {
  //       _downloadTasks[taskId] = fileName;

  //       // Wait for download completion
  //       await _waitForDownloadCompletion(taskId);

  //       final filePath = '$downloadPath/$fileName';
  //       return filePath;
  //     }

  //     return null;
  //   } catch (e) {
  //     print('Download error: $e');
  //     _downloadProgressController.add(
  //       DownloadProgress(
  //         received: 0,
  //         total: 100,
  //         percentage: 0.0,
  //         speed: 0.0,
  //         status: DownloadStatus.failed,
  //       ),
  //     );
  //     return null;
  //   }
  // }

  Future<void> _waitForDownloadCompletion(String taskId) async {
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = downloadProgressStream.listen((progress) {
      if (progress.taskId == taskId) {
        if (progress.status == DownloadStatus.completed ||
            progress.status == DownloadStatus.failed) {
          subscription.cancel();
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  Future<void> pauseDownload(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  Future<void> resumeDownload(String taskId) async {
    await FlutterDownloader.resume(taskId: taskId);
  }

  Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  Future<void> retryDownload(String taskId) async {
    await FlutterDownloader.retry(taskId: taskId);
  }

  Future<List<DownloadTask>?> getDownloadTasks() async {
    return await FlutterDownloader.loadTasks();
  }

  void dispose() {
    _downloadProgressController.close();
    _port.close();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13 and above
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // For Android 10 and below
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      // For Android 11 and above
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
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
  final String? taskId;

  DownloadProgress({
    required this.received,
    required this.total,
    required this.percentage,
    required this.speed,
    required this.status,
    this.taskId,
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
