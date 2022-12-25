import 'dart:io';
import 'package:ffmpeg_helper/ffmpeg_helper.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? selectedFile;
  bool ffmpegPresent = false;
  ValueNotifier<FFMpegProgress> downloadProgress =
      ValueNotifier<FFMpegProgress>(FFMpegProgress(
    downloaded: 0,
    fileSize: 0,
    phase: FFMpegProgressPhase.inactive,
  ));
  late FFMpegHelper ffmpeg;

  @override
  void initState() {
    super.initState();
    ffmpeg = FFMpegHelper(ffMpegConfigurator: FFMpegWindowsConfigurator());
  }

  Future<void> selectVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null) {
      if (result.files.isNotEmpty) {
        selectedFile = File(result.files.first.path!);
        setState(() {});
      }
    }
  }

  Future<void> runFFprobe() async {
    if (selectedFile == null) return;
    MediaInformation? res = await ffmpeg.runProbe(selectedFile!.path);
    if (res != null) {
      print('${res.getBitrate()}');
      for (StreamInformation stream in res.getStreams()) {
        print(
            "---------\n FFprobe result \n Bitrate: ${stream.getBitrate()} \n Height: ${stream.getHeight()} \n Width: ${stream.getWidth()} \n ------------------");
      }
    } else {
      print('ffprobe null');
    }
  }

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

  Future<void> downloadFFMpeg() async {
    await ffmpeg.ffMpegConfigurator!.initialize();
    bool success = await ffmpeg.ffMpegConfigurator!.setupFFMpeg(
      onProgress: (FFMpegProgress progress) {
        downloadProgress.value = progress;
      },
    );
    setState(() {
      ffmpegPresent = success;
    });
  }

  Future<void> runFFMpeg() async {
    if ((selectedFile == null) || (ffmpegPresent == false)) return;
    Directory appDocDir = await getApplicationDocumentsDirectory();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Platform.isWindows
          ? null
          : AppBar(
              title: const Text('FFMpeg Testing'),
            ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                label: const Text('Select Video File'),
                icon: const Icon(Icons.video_file),
                onPressed: selectVideoFile,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                label: const Text('Show Video File details'),
                icon: const Icon(Icons.info),
                onPressed: runFFprobe,
              ),
              if (!ffmpegPresent) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  label: const Text('Check FFMpeg Setup'),
                  icon: const Icon(Icons.check),
                  onPressed: checkFFMpeg,
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  label: const Text('Setup FFMpeg on windows'),
                  icon: const Icon(Icons.download),
                  onPressed: downloadFFMpeg,
                ),
              ],
              if (ffmpegPresent) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  label: const Text('Process Video File'),
                  icon: const Icon(Icons.run_circle),
                  onPressed: runFFMpeg,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: ValueListenableBuilder(
                  valueListenable: downloadProgress,
                  builder: (BuildContext context, FFMpegProgress value, _) {
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
            ],
          ),
        ),
      ),
    );
  }
}
