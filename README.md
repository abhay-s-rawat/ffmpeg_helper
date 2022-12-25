<p >
<a href="https://www.buymeacoffee.com/abhayrawat" target="_blank"><img align="center" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30px" width= "108px"></a>
</p> 

# ffmpeg_helper
FFmpeg commands helper for flutter with support for setup on windows platform.

# This uses ffmpeg_kit_flutter_min_gpl package for android/ios/macos
```dart
// Initialize
  late FFMpegHelper ffmpeg;

  @override
  void initState() {
    super.initState();
    ffmpeg = FFMpegHelper(ffMpegConfigurator: FFMpegWindowsConfigurator());
  }
```
```
// Command builder
// Use prebuilt args and filters or create custom ones
final FFMpegCommand cliCommand = FFMpegCommand(
      inputs: [
        FFMpegInput.asset(selectedFile!.path),
      ],
      args: [
        const LogLevelArgument(LogLevel.info),
        const OverwriteArgument(),
        const TrimArgument(
          start: Duration(seconds: 0),
          end: Duration(seconds: 10),
        ),
      ],
      filterGraph: FilterGraph(
        chains: [
          FilterChain(
            inputs: [],
            filters: [
              ScaleFilter(
                height: 300,
                width: -2,
              ),
            ],
            outputs: [],
          ),
        ],
      ),
      outputFilepath: path.join(appDocDir.path, "ffmpegtest.mp4"),
    );
    FFMpegHelperSession session = await ffmpeg.runAsync(
      cliCommand,
      statisticsCallback: (Statistics statistics) {
        print('bitrate: ${statistics.getBitrate()}');
      },
    );
```
# Run FFMpeg and get session so that user can cancel it later.
```
Future<FFMpegHelperSession> runAsync(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
    Function(File? outputFile)? onComplete,
    Function(Log)? logCallback,
  })
```
# Run FFMpeg as future.
```
Future<File?> runSync(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
  })
```
# Run ffprobe
```
Future<MediaInformation?> runProbe(String filePath)
```
# Setup FFMPEG for windows
```
// check on windows
Future<void> checkFFMpeg() async {
    bool present = await ffmpeg.ffMpegConfigurator!.isFFMpegPresent();
    ffmpegPresent = present;
    if (present) {
      print('ffmpeg available');
    } else {
      print('ffmpeg needs to setup');
    }
    setState(() {});
  }
```
```
// Download on windows if ffmpeg is present (only check for windows)
Future<void> downloadFFMpeg() async {
    await ffmpeg.ffMpegConfigurator!.initialize();
    bool success = await ffmpeg.ffMpegConfigurator!.setupFFMpeg(
      onProgress: (FFMpegProgress progress) {
        downloadProgress.value = progress;
        /* print(
            'downloading ffmpeg: ${((received / total) * 100).toStringAsFixed(2)}'); */
      },
    );
    setState(() {
      ffmpegPresent = success;
    });
  }
```
```
// check setup progress on windows
// On windows if ffmpeg is not present it will download official zip file and extract on doc directory of app.
SizedBox(
                width: 300,
                child: ValueListenableBuilder(
                  valueListenable: downloadProgress,
                  builder: (BuildContext context, FFMpegProgress value, _) {
                    //print(value.downloaded / value.fileSize);
                    double? prog;
                    if ((value.downloaded != 0) && (value.fileSize != 0)) {
                      prog = value.downloaded / value.fileSize;
                    } else {
                      prog = 0;
                    }
                    if (value.phase == FFMpegProgressPhase.decompressing) {
                      prog = null;
                    }
                    if (value.phase == FFMpegProgressPhase.inactive) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(value.phase.name),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(value: prog),
                      ],
                    );
                  },
                ),
              ),
```