import 'dart:io';
import 'package:ffmpeg_helper/ffmpeg_helper.dart';

class ThumbnailCreator {
  static Future<FFMpegHelperSession> getThumbnailFileAsync({
    required String videoPath,
    required Duration fromDuration,
    required String outputPath,
    String? ffmpegPath,
    FilterGraph? filterGraph,
    int qualityPercentage = 100,
    Function(Statistics statistics)? statisticsCallback,
    Function(File? outputFile)? onComplete,
    FFMpegConfigurator? ffMpegConfigurator,
  }) async {
    int quality = 1;
    if ((qualityPercentage > 0) && (qualityPercentage < 100)) {
      quality = (((100 - qualityPercentage) * 31) / 100).ceil();
    }
    final FFMpegCommand cliCommand = FFMpegCommand(
      returnProgress: true,
      inputs: [FFMpegInput.asset(videoPath)],
      args: [
        const OverwriteArgument(),
        SeekArgument(fromDuration),
        const CustomArgument(["-frames:v", '1']),
        CustomArgument(["-q:v", '$quality']),
      ],
      outputFilepath: outputPath,
      filterGraph: filterGraph,
    );
    FFMpegHelperSession session =
        await FFMpegHelper(ffMpegConfigurator: ffMpegConfigurator).runAsync(
      cliCommand,
      onComplete: onComplete,
      statisticsCallback: statisticsCallback,
    );
    return session;
  }

  static Future<File?> getThumbnailFileSync({
    required String videoPath,
    required Duration fromDuration,
    required String outputPath,
    String? ffmpegPath,
    FilterGraph? filterGraph,
    int qualityPercentage = 100,
    Function(Statistics statistics)? statisticsCallback,
    Function(File? outputFile)? onComplete,
    FFMpegConfigurator? ffMpegConfigurator,
  }) async {
    int quality = 1;
    if ((qualityPercentage > 0) && (qualityPercentage < 100)) {
      quality = (((100 - qualityPercentage) * 31) / 100).ceil();
    }
    final FFMpegCommand cliCommand = FFMpegCommand(
      returnProgress: true,
      inputs: [FFMpegInput.asset(videoPath)],
      args: [
        const OverwriteArgument(),
        SeekArgument(fromDuration),
        const CustomArgument(["-frames:v", '1']),
        CustomArgument(["-q:v", '$quality']),
      ],
      outputFilepath: outputPath,
      filterGraph: filterGraph,
    );
    File? session =
        await FFMpegHelper(ffMpegConfigurator: ffMpegConfigurator).runSync(
      cliCommand,
      statisticsCallback: statisticsCallback,
    );
    return session;
  }
}
