// Only needed for windows
abstract class FFMpegConfigurator {
  String? ffmpegBinDirectory;
  Future<void> initialize();
  Future<bool> isFFMpegPresent();
  Future<bool> setupFFMpeg({
    void Function(FFMpegProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  });
}

class FFMpegProgress {
  FFMpegProgressPhase phase;
  int fileSize;
  int downloaded;

  FFMpegProgress({
    required this.phase,
    required this.fileSize,
    required this.downloaded,
  });
}

enum FFMpegProgressPhase {
  downloading,
  decompressing,
  inactive,
}
