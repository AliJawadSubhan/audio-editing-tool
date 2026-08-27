import 'package:audio_editing_tool/src/file_services/audio_exceptions.dart';
import 'package:audio_editing_tool/src/file_services/core_audio_editing_tools.dart';
import 'package:audio_editing_tool/src/file_services/file_service.dart';

class AudioEditingController {
  String? _filePath;
  String? _tempOutPutPath;
  String? _originalFilePath;

  final List<String> _sessionFiles = [];

  /// Current index in the edit history. -1 means original file, 0 means first edit, etc.
  int _currentHistoryIndex = -1;

  /// Returns the list of all edited audio files for histroy
  List<String> get editedAudioFiles => _sessionFiles;

  /// Sets the current audio file path.
  Future<void> init(String path) async {
    _filePath = path;
    _originalFilePath = path;
    _currentHistoryIndex = -1;
    await _getOutPutFilePath();
  }

  /// Returns the currently edited file path.
  String? get filePath => _filePath;

  bool get canUndo => _currentHistoryIndex >= 0;

  /// Reverts to the previous version of the audio file.
  /// Returns true if undo was successful, false if there's nothing to undo.
  Future<bool> undo() async {
    if (!canUndo) return false;

    if (_currentHistoryIndex == 0) {
      _filePath = _originalFilePath;
      _currentHistoryIndex = -1;
    } else if (_currentHistoryIndex > 0) {
      _currentHistoryIndex--;
      _filePath = _sessionFiles[_currentHistoryIndex];
    }

    await _getOutPutFilePath();
    return true;
  }

  final fileService = FileServices();

  Future<void> _getOutPutFilePath() async {
    if (_filePath != null) {
      _tempOutPutPath =
          await fileService.getOutputFilePath(_getFileExtension(_filePath!));
    } else {
      _tempOutPutPath = await fileService.getOutputFilePath();
    }
  }

  void _handleSuccess(String newPath) {
    _filePath = newPath;

    if (_currentHistoryIndex == -1) {
      _sessionFiles.clear();
    } else if (_currentHistoryIndex < _sessionFiles.length - 1) {
      _sessionFiles.removeRange(_currentHistoryIndex + 1, _sessionFiles.length);
    }

    _sessionFiles.add(newPath);
    _currentHistoryIndex = _sessionFiles.length - 1;
    _getOutPutFilePath();
  }

  /// Get Audio duration in Unit: Milliseconds
  Future<int> audioDuration() async {
    assert(_filePath != null, "filePath is not set. Use setFilePath first.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    try {
      final result = await CoreAudioEditingTools.getAudioDuration(_filePath!);

      if (!result.$1) {
        throw AudioEditingException("Audio Duration error: ${result.$2}");
      } else {
        final audioDuration = result.$2 as int;
        return audioDuration;
      }
    } catch (e) {
      throw AudioEditingException("Audio Duration error: $e");
    }
  }

  /// Trims the current audio between [start] and [end] seconds.
  Future<void> trim(double start, double end) async {
    assert(_filePath != null, "filePath is not set. Use setFilePath first.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    assert(end > start, "End time must be greater than start time.");

    final result = await CoreAudioEditingTools.trimAudio(
      _filePath!,
      _tempOutPutPath!,
      start,
      end,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Trimming failed: ${result.$2}");
    }
  }

  /// Changes volume of the current audio by [factor] (e.g., 0.5 = lower, 2.0 = louder).
  Future<void> changeVolume(double factor) async {
    assert(_filePath != null, "filePath is not set.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    assert(factor > 0, "Volume factor must be greater than 0.");

    final result = await CoreAudioEditingTools.changeVolume(
      _filePath!,
      _tempOutPutPath!,
      factor,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Changing volume failed: ${result.$2}");

      // throw "";
    }
  }

  /// Changes playback speed of the current audio by [factor].
  Future<void> changeSpeed(double factor) async {
    assert(_filePath != null, "filePath is not set.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    assert(factor > 0, "Speed factor must be greater than 0.");

    final result = await CoreAudioEditingTools.changeSpeed(
      _filePath!,
      _tempOutPutPath!,
      factor,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Changing speed failed: ${result.$2}");
    }
  }

  /// Applies a fade-in effect to the start of the audio over [durationSeconds].
  Future<void> fadeIn(double durationSeconds) async {
    assert(_filePath != null, "filePath is not set.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    assert(durationSeconds > 0, "Fade-in duration must be positive.");

    final result = await CoreAudioEditingTools.fadeIn(
      _filePath!,
      _tempOutPutPath!,
      durationSeconds,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Fade-in failed: ${result.$2}");
    }
  }

  /// Applies a fade-out effect over the last [durationSeconds] of the audio.
  Future<void> fadeOut(double durationSeconds) async {
    assert(_filePath != null, "filePath is not set.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    assert(durationSeconds > 0, "Fade-out duration must be positive.");

    final result = await CoreAudioEditingTools.fadeOutAuto(
      _filePath!,
      _tempOutPutPath!,
      durationSeconds,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Fade-out failed: ${result.$2}");
    }
  }

  /// Converts the audio to a new format using [fileType] (e.g., ".mp3").
  Future<void> convertTo(String fileType) async {
    assert(_filePath != null, "filePath is not set.");
    assert(fileType.isNotEmpty, "fileType extension cannot be empty.");

    final result = await CoreAudioEditingTools.convertFormat(
      _filePath!,
      fileType,
    );

    if (result.$1) {
      _handleSuccess(result.$2);
    } else {
      throw AudioEditingException("Convert failed: ${result.$2}");
    }
  }

  /// Compresses the current audio using a default bitrate 96k.
  Future<void> compress() async {
    assert(_filePath != null, "filePath is not set.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");

    final result = await CoreAudioEditingTools.compressAudio(
      _filePath!,
      _tempOutPutPath!,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Compress failed: ${result.$2}");
    }
  }

  /// Merges the current audio with [mergeAudios]. Crossfading not applied.
  Future<void> mergeAudios(List<String> mergeAudios) async {
    assert(_filePath != null, "filePath is not set.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    assert(mergeAudios.isNotEmpty, "No audios provided to merge.");

    final allInputs = [_filePath!, ...mergeAudios];

    final result = await CoreAudioEditingTools.mergeAudios(
      allInputs,
      _tempOutPutPath!,
      startOffsetMs: 5000,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Merging audios failed: ${result.$2}");
    }
  }

  /// Adds a watermark audio either at the start or end depending on [placeWatermarkAtStart].
  Future<void> addWaterMark(
    String watermarkAudio,
    bool placeWatermarkAtStart,
  ) async {
    assert(_filePath != null, "filePath is not set.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    assert(watermarkAudio.isNotEmpty, "Watermark audio path is empty.");

    final result = await CoreAudioEditingTools.addWatermark(
      _filePath!,
      _tempOutPutPath!,
      watermarkAudio,
      placeWatermarkAtStart,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Watermarking audio failed: ${result.$2}");
    }
  }

  /// Applies a crossfade transition between the current audio and [input].
  Future<void> crossFade(String input, double durationTransition) async {
    assert(_filePath != null, "filePath is not set.");
    assert(_tempOutPutPath != null, "tempOutPutPath is not initialized.");
    assert(input.isNotEmpty, "Crossfade input path cannot be empty.");
    assert(durationTransition > 0, "Crossfade duration must be positive.");

    final result = await CoreAudioEditingTools.crossfade(
      _filePath!,
      input,
      _tempOutPutPath!,
      durationTransition,
    );

    if (result.$1) {
      _handleSuccess(_tempOutPutPath!);
    } else {
      throw AudioEditingException("Crossfade audio failed: ${result.$2}");
    }
  }

  /// Helper method to extract file extension from file path
  String _getFileExtension(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return '.$extension';
  }

  /// Deletes all temporary files created during the editing session.
  Future<void> dispose() async {
    await fileService.dispose();
    _sessionFiles.clear();
    _filePath = null;
    _tempOutPutPath = null;
    _originalFilePath = null;
    _currentHistoryIndex = -1;
  }
}
