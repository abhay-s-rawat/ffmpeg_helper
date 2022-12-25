import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:ffmpeg_helper/ffmpeg_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FFMpegWindowsConfigurator implements FFMpegConfigurator {
  final String ffmpegUrl =
      "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip";
  String? tempFolderPath;
  @override
  String? ffmpegBinDirectory;
  String? ffmpegInstallationPath;

  FFMpegWindowsConfigurator();

  @override
  Future<void> initialize() async {
    if (Platform.isWindows) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String appName = packageInfo.appName;
      Directory tempDir = await getTemporaryDirectory();
      tempFolderPath = path.join(tempDir.path, "ffmpeg");
      Directory appDocDir = await getApplicationDocumentsDirectory();
      ffmpegInstallationPath = path.join(appDocDir.path, appName, "ffmpeg");
      ffmpegBinDirectory = path.join(
          ffmpegInstallationPath!, "ffmpeg-master-latest-win64-gpl", "bin");
    }
  }

  @override
  Future<bool> isFFMpegPresent() async {
    if (Platform.isWindows) {
      if ((ffmpegBinDirectory == null) || (tempFolderPath == null)) {
        await initialize();
      }
      File ffmpeg = File(path.join(ffmpegBinDirectory!, "ffmpeg.exe"));
      File ffprobe = File(path.join(ffmpegBinDirectory!, "ffprobe.exe"));
      if ((await ffmpeg.exists()) && (await ffprobe.exists())) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  @override
  Future<bool> setupFFMpeg({
    CancelToken? cancelToken,
    void Function(FFMpegProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (Platform.isWindows) {
      if ((ffmpegBinDirectory == null) || (tempFolderPath == null)) {
        await initialize();
      }
      Directory tempDir = Directory(tempFolderPath!);
      if (await tempDir.exists() == false) {
        await tempDir.create(recursive: true);
      }
      Directory installationDir = Directory(ffmpegInstallationPath!);
      if (await installationDir.exists() == false) {
        await installationDir.create(recursive: true);
      }
      final String ffmpegZipPath = path.join(tempFolderPath!, "ffmpeg.zip");
      final File tempZipFile = File(ffmpegZipPath);
      if (await tempZipFile.exists() == false) {
        try {
          Dio dio = Dio();
          Response response = await dio.download(
            ffmpegUrl,
            ffmpegZipPath,
            cancelToken: cancelToken,
            onReceiveProgress: (int received, int total) {
              onProgress?.call(FFMpegProgress(
                downloaded: received,
                fileSize: total,
                phase: FFMpegProgressPhase.downloading,
              ));
            },
            queryParameters: queryParameters,
          );
          if (response.statusCode == HttpStatus.ok) {
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.decompressing,
            ));
            await compute(extractZipFileIsolate, {
              'zipFile': tempZipFile.path,
              'targetPath': ffmpegInstallationPath,
            });
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.inactive,
            ));
            return true;
          } else {
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.inactive,
            ));
            return false;
          }
        } catch (e) {
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return false;
        }
      } else {
        onProgress?.call(FFMpegProgress(
          downloaded: 0,
          fileSize: 0,
          phase: FFMpegProgressPhase.decompressing,
        ));
        try {
          await compute(extractZipFileIsolate, {
            'zipFile': tempZipFile.path,
            'targetPath': ffmpegInstallationPath,
          });
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return true;
        } catch (e) {
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return false;
        }
      }
    } else {
      onProgress?.call(FFMpegProgress(
        downloaded: 0,
        fileSize: 0,
        phase: FFMpegProgressPhase.inactive,
      ));
      return true;
    }
  }

  static Future<void> extractZipFileIsolate(Map data) async {
    String? zipFilePath = data['zipFile'];
    String? targetPath = data['targetPath'];
    if ((zipFilePath != null) && (targetPath != null)) {
      await extractFileToDisk(zipFilePath, targetPath);
    }
  }
}
