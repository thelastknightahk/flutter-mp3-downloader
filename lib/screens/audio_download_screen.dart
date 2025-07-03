import 'package:audio_background_download/service/audio_download_service.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

class AudioDownloadScreen extends StatefulWidget {
  final AudioHandler audioHandler;

  const AudioDownloadScreen({super.key, required this.audioHandler});

  @override
  State<AudioDownloadScreen> createState() => _AudioDownloadScreenState();
}

class _AudioDownloadScreenState extends State<AudioDownloadScreen> {
  final String _audioUrl =
      "https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.mp3";
  String? _downloadedFilePath;
  bool _isDownloading = false;

  AudioDownloadService get audioService =>
      widget.audioHandler as AudioDownloadService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MP3 Background Downloader'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audio URL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _audioUrl,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Download Progress Section
            StreamBuilder<DownloadProgress>(
              stream: audioService.downloadProgressStream,
              builder: (context, snapshot) {
                final progress = snapshot.data;

                if (progress != null &&
                    progress.status == DownloadStatus.downloading) {
                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Download Progress',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${progress.percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: progress.percentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                progress.formattedSize,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                progress.formattedSpeed,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 20),

            // Download Button
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadAudio,
              icon:
                  _isDownloading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.download),
              label: Text(_isDownloading ? 'Downloading...' : 'Download MP3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 10),

            // Play Downloaded Audio Button
            ElevatedButton.icon(
              onPressed:
                  _downloadedFilePath != null ? _playDownloadedAudio : null,
              icon: const Icon(Icons.play_circle_filled),
              label: const Text('Play Downloaded Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 10),

            // Stream Audio Button
            ElevatedButton.icon(
              onPressed: _streamAudio,
              icon: const Icon(Icons.stream),
              label: const Text('Stream Audio (No Download)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 30),

            // Audio Controls Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<PlaybackState>(
                  stream: widget.audioHandler.playbackState,
                  builder: (context, snapshot) {
                    final playbackState = snapshot.data;
                    final isPlaying = playbackState?.playing ?? false;
                    final processingState =
                        playbackState?.processingState ??
                        AudioProcessingState.idle;

                    return Column(
                      children: [
                        const Text(
                          'Audio Controls',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed:
                                  isPlaying
                                      ? widget.audioHandler.pause
                                      : widget.audioHandler.play,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              onPressed: widget.audioHandler.stop,
                              icon: const Icon(
                                Icons.stop_circle,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Status: ${processingState.name.toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        if (_downloadedFilePath != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Downloaded: ${_downloadedFilePath!.split('/').last}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAudio() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final filePath = await audioService.downloadMp3(
        _audioUrl,
        fileName: 'test_audio.mp3',
      );

      if (filePath != null) {
        setState(() {
          _downloadedFilePath = filePath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Download completed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Download failed!'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _playDownloadedAudio() async {
    if (_downloadedFilePath != null) {
      await audioService.playFromFile(_downloadedFilePath!);
    }
  }

  Future<void> _streamAudio() async {
    await audioService.playFromUrl(_audioUrl);
  }
}
