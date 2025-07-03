# Flutter MP3 Background Downloader

A Flutter application that enables downloading and playing MP3 audio files in the background with real-time progress tracking. Perfect for meditation apps, podcasts, or any audio content that needs to be downloaded and played offline.

## 📱 Features

- **Background Download**: Download MP3 files even when the app is minimized
- **Real-time Progress**: Live download progress with percentage, speed, and file size
- **Background Audio Playback**: Play audio in the background using foreground service
- **Media Controls**: Control playback from notification panel and lock screen
- **Stream & Download**: Option to stream directly or download first then play
- **Cross-platform**: Works on both Android and iOS
- **Permission Handling**: Automatically requests necessary permissions
- **Modern UI**: Clean, intuitive interface with progress indicators

## 🚀 Screenshots

### Download Progress
- Real-time percentage display (e.g., "87.5%")
- Visual progress bar with smooth animations
- Download speed tracking (B/s, KB/s, MB/s)
- File size display ("5.2 MB / 12.8 MB")

### Background Playback
- Foreground service notification on Android
- Media controls in notification panel
- Lock screen audio controls
- Background audio mode on iOS

## 🛠️ Installation

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / VS Code with Flutter plugin
- iOS development setup (for iOS builds)

### Dependencies
Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.3.2                    # HTTP client for downloads
  path_provider: ^2.1.1          # File system paths
  permission_handler: ^11.0.1    # Runtime permissions
  just_audio: ^0.9.35           # Audio player
  just_audio_background: ^0.0.1-beta.11  # Background audio
  flutter_downloader: ^1.11.6    # Background downloads
  audio_service: ^0.18.12        # Audio service management
```

### Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/thelastknightahk/flutter-mp3-downloader.git
   cd flutter-mp3-downloader
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Android** (see Android Setup section below)

4. **Configure iOS** (see iOS Setup section below)

5. **Run the app**:
   ```bash
   flutter run
   ```

## ⚙️ Android Setup

### 1. Update AndroidManifest.xml
Location: `android/app/src/main/AndroidManifest.xml`

Add these permissions:
```xml
<!-- Internet and storage permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Foreground service permissions -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

Add services in `<application>` tag:
```xml
<!-- Audio Service -->
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="false">
</service>

<!-- File Provider -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.flutter_downloader.provider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/provider_paths" />
</provider>
```

### 2. Create provider_paths.xml
Location: `android/app/src/main/res/xml/provider_paths.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
</paths>
```

### 3. Update build.gradle
Location: `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

## 🍎 iOS Setup

### Update Info.plist
Location: `ios/Runner/Info.plist`

Add these keys inside `<dict>`:
```xml
<!-- Allow HTTP downloads -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- Background modes -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>background-fetch</string>
    <string>background-processing</string>
</array>

<!-- Audio usage description -->
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to play audio in the background</string>
```

## 📖 Usage

### Basic Usage

1. **Download MP3**: Tap "Download MP3" to start downloading
2. **Monitor Progress**: Watch real-time progress with speed and percentage
3. **Play Downloaded**: Once downloaded, tap "Play Downloaded Audio"
4. **Stream Direct**: Or tap "Stream Audio" to play without downloading
5. **Background Control**: Use notification controls to manage playback

### Code Example

```dart
// Initialize the audio service
final audioHandler = await AudioService.init(
  builder: () => AudioDownloadService(),
  config: const AudioServiceConfig(
    androidNotificationChannelId: 'com.example.app.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  ),
);

// Download MP3 file
String? filePath = await audioService.downloadMp3(
  'https://example.com/audio.mp3',
  fileName: 'my_audio.mp3',
);

// Play downloaded file
if (filePath != null) {
  await audioService.playFromFile(filePath);
}
```

### Progress Monitoring

```dart
// Listen to download progress
StreamBuilder<DownloadProgress>(
  stream: audioService.downloadProgressStream,
  builder: (context, snapshot) {
    final progress = snapshot.data;
    if (progress != null) {
      return LinearProgressIndicator(
        value: progress.percentage / 100,
      );
    }
    return Container();
  },
)
```

## 🏗️ Architecture

### Core Components

1. **AudioDownloadService**: Handles downloads and audio playback
2. **AudioDownloadScreen**: Main UI with progress indicators
3. **DownloadProgress**: Model for tracking download state
4. **AudioService**: Background service for media playback

### Data Flow

```
User Input → AudioDownloadService → Download Progress Stream → UI Updates
                    ↓
            Background Download → File Storage → Audio Playback
```

## 🔧 Configuration

### Custom Audio URLs
Change the audio URL in `AudioDownloadScreen`:
```dart
final String _audioUrl = 'https://your-audio-url.com/file.mp3';
```

### File Storage Location
Files are stored in the app's documents directory:
```dart
final directory = await getApplicationDocumentsDirectory();
final downloadPath = '${directory.path}/downloads';
```

### Download Settings
Customize Dio settings in `AudioDownloadService`:
```dart
final Dio _dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
));
```

## 🐛 Troubleshooting

### Common Issues

1. **Download Fails**:
   - Check internet connection
   - Verify audio URL is accessible
   - Ensure storage permissions are granted

2. **Background Playback Not Working**:
   - Verify foreground service permissions (Android)
   - Check background modes in Info.plist (iOS)
   - Ensure AudioService is properly initialized

3. **Progress Not Updating**:
   - Check if StreamBuilder is properly set up
   - Verify download progress stream is active
   - Ensure UI is listening to the correct stream

### Debug Mode

Enable debug logging in `main.dart`:
```dart
await FlutterDownloader.initialize(
  debug: true,
  ignoreSsl: true,
);
```

## 📱 Platform-Specific Notes

### Android
- Uses foreground service for background downloads
- Requires notification permission for media controls
- Files stored in app-specific directory
- Works with Android 6.0+ (API 23+)

### iOS
- Uses background audio mode
- Automatic media controls in Control Center
- Files stored in app documents directory
- Works with iOS 12.0+

## 🔒 Permissions

### Android Permissions
- `INTERNET`: Download audio files
- `WRITE_EXTERNAL_STORAGE`: Save downloaded files
- `FOREGROUND_SERVICE`: Background operations
- `WAKE_LOCK`: Keep device awake during downloads

### iOS Permissions
- Background audio mode for continuous playback
- Network access for downloads
- File system access for storage

## 📊 Performance

### Optimization Tips
1. Use efficient audio formats (MP3, AAC)
2. Implement file caching to avoid re-downloads
3. Monitor memory usage during playback
4. Use appropriate audio quality settings

### Resource Usage
- Memory: ~50-100MB during active download/playback
- Storage: Files stored in app directory
- Network: Efficient chunked downloads with progress tracking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [just_audio](https://pub.dev/packages/just_audio) - Excellent audio player
- [audio_service](https://pub.dev/packages/audio_service) - Background audio service
- [dio](https://pub.dev/packages/dio) - Powerful HTTP client
- [flutter_downloader](https://pub.dev/packages/flutter_downloader) - Background downloads

## 📞 Support

For support, email your-email@example.com or create an issue in the repository.

## 🚀 Roadmap

- [ ] Multiple file downloads
- [ ] Playlist support
- [ ] Download queue management
- [ ] Offline playback indicators
- [ ] Audio file metadata display
- [ ] Custom notification layouts
- [ ] Download resume functionality
