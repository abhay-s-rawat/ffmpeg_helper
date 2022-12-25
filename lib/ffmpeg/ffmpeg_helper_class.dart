import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../ffmpeg_helper.dart';
import 'package:path/path.dart' as path;

class FFMpegHelper {
  final FFMpegConfigurator? ffMpegConfigurator;
  FFMpegHelper({this.ffMpegConfigurator});

  Future<FFMpegHelperSession> runAsync(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
    Function(File? outputFile)? onComplete,
  }) async {
    if (Platform.isWindows) {
      return _runAsyncOnWindows(
        command,
        statisticsCallback: statisticsCallback,
        onComplete: onComplete,
      );
    } else {
      return _runAsyncOnNonWindows(
        command,
        statisticsCallback: statisticsCallback,
        onComplete: onComplete,
      );
    }
  }

  Future<FFMpegHelperSession> _runAsyncOnWindows(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
    Function(File? outputFile)? onComplete,
  }) async {
    Process process = await _startWindowsProcess(
      command,
      statisticsCallback: statisticsCallback,
    );
    process.exitCode.then((value) {
      if (value == ReturnCode.success) {
        onComplete?.call(File(command.outputFilepath));
      } else {
        onComplete?.call(null);
      }
    });
    return FFMpegHelperSession(
      windowSession: process,
      cancelSession: () async {
        process.kill();
      },
    );
  }

  Future<FFMpegHelperSession> _runAsyncOnNonWindows(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
    Function(File? outputFile)? onComplete,
  }) async {
    FFmpegSession sess = await FFmpegKit.executeAsync(
      command.toCli().join(' '),
      (FFmpegSession session) async {
        final code = await session.getReturnCode();
        if (code?.isValueSuccess() == true) {
          onComplete?.call(File(command.outputFilepath));
        } else {
          onComplete?.call(null);
        }
      },
      null,
      (Statistics statistics) {
        statisticsCallback?.call(statistics);
      },
    );
    return FFMpegHelperSession(
      nonWindowSession: sess,
      cancelSession: () async {
        await sess.cancel();
      },
    );
  }

  Future<File?> runSync(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
  }) async {
    if (Platform.isWindows) {
      return _runSyncOnWindows(
        command,
        statisticsCallback: statisticsCallback,
      );
    } else {
      return _runSyncOnNonWindows(
        command,
        statisticsCallback: statisticsCallback,
      );
    }
  }

  Future<Process> _startWindowsProcess(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
  }) async {
    String ffmpeg = 'ffmpeg';
    if ((ffMpegConfigurator != null) &&
        (ffMpegConfigurator!.ffmpegBinDirectory != null)) {
      ffmpeg = path.join(ffMpegConfigurator!.ffmpegBinDirectory!, "ffmpeg.exe");
    }
    Process process = await Process.start(
      ffmpeg,
      command.toCli(),
    );
    process.stdout.transform(utf8.decoder).listen((String event) {
      List<String> data = event.split("\n");
      for (String element in data) {
        List<String> kv = element.split("=");
        Map<String, dynamic> temp = {};
        if (kv.length == 2) {
          temp[kv.first] = kv.last;
        }
        if (temp.isNotEmpty) {
          try {
            statisticsCallback?.call(Statistics(
              process.pid,
              int.parse(temp['frame']),
              double.parse(temp['fps']),
              double.parse(temp['stream_0_0_q']),
              int.parse(temp['total_size']),
              int.parse(temp['out_time_ms']),
              double.parse(temp['bitrate']),
              double.parse(temp['speed']),
            ));
          } catch (e) {}
        }
      }
    });
    process.stderr.transform(utf8.decoder).listen((event) {
      print("err: $event");
    });
    return process;
  }

  Future<File?> _runSyncOnWindows(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
  }) async {
    Process process = await _startWindowsProcess(
      command,
      statisticsCallback: statisticsCallback,
    );
    if (await process.exitCode == ReturnCode.success) {
      return File(command.outputFilepath);
    } else {
      return null;
    }
  }

  Future<File?> _runSyncOnNonWindows(
    FFMpegCommand command, {
    Function(Statistics statistics)? statisticsCallback,
  }) async {
    Completer<File?> completer = Completer<File?>();
    await FFmpegKit.executeAsync(
      command.toCli().join(' '),
      (FFmpegSession session) async {
        final code = await session.getReturnCode();
        if (code?.isValueSuccess() == true) {
          if (!completer.isCompleted) {
            completer.complete(File(command.outputFilepath));
          }
        } else {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      },
      null,
      (Statistics statistics) {
        statisticsCallback?.call(statistics);
      },
    );
    return completer.future;
  }

  Future<MediaInformation?> runProbe(String filePath) async {
    if (Platform.isWindows) {
      return _runProbeOnWindows(filePath);
    } else {
      return _runProbeOnNonWindows(filePath);
    }
  }

  Future<MediaInformation?> _runProbeOnNonWindows(String filePath) async {
    Completer<MediaInformation?> completer = Completer<MediaInformation?>();
    try {
      await FFprobeKit.getMediaInformationAsync(filePath,
          (MediaInformationSession session) async {
        final MediaInformation? information = session.getMediaInformation();
        if (information != null) {
          if (!completer.isCompleted) {
            completer.complete(information);
          }
        } else {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      });
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    return completer.future;
  }

  Future<MediaInformation?> _runProbeOnWindows(String filePath) async {
    String ffprobe = 'ffprobe';
    if ((ffMpegConfigurator != null) &&
        (ffMpegConfigurator!.ffmpegBinDirectory != null)) {
      ffprobe =
          path.join(ffMpegConfigurator!.ffmpegBinDirectory!, "ffprobe.exe");
    }
    final result = await Process.run(ffprobe, [
      '-v',
      'quiet',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      '-show_chapters',
      filePath,
    ]);
    if (result.stdout == null ||
        result.stdout is! String ||
        (result.stdout as String).isEmpty) {
      return null;
    }
    if (result.exitCode == ReturnCode.success) {
      try {
        final json = jsonDecode(result.stdout);
        return MediaInformation(json);
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
  }
}
