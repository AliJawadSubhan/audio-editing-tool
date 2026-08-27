import 'package:audio_editing_tool/audio_editing_tool.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as dev; // Standard import for log()

class AudioViewController extends StatelessWidget {
  const AudioViewController({super.key});

  @override
  Widget build(BuildContext context) {
    return const ControllerDemoPage();
  }
}

class ControllerDemoPage extends StatefulWidget {
  const ControllerDemoPage({super.key});

  @override
  State<ControllerDemoPage> createState() => _ControllerDemoPageState();
}

class _ControllerDemoPageState extends State<ControllerDemoPage> {
  final AudioEditingController _controller = AudioEditingController();
  String? _selectedFile;
  String? _outputFile;
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;
  double? _audioDuration;

  // Feature parameters
  double _trimStart = 0.0;
  double _trimEnd = 10.0;
  double _volumeFactor = 1.0;
  double _speedFactor = 1.0;
  double _fadeInDuration = 1.0;
  double _fadeOutDuration = 1.0;
  String _convertFormat = '.mp3';
  String? _mergeFile;
  String? _watermarkFile;
  bool _watermarkAtStart = true;
  String? _crossfadeFile;
  double _crossfadeDuration = 1.0;

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final result = await FilePicker.pickFiles(type: FileType.audio);
      if (result.isNotEmpty && result.single.path != null) {
        _selectedFile = result.single.path;
        await _controller.init(_selectedFile!);
        _outputFile = _selectedFile;
        log("Audio Pick File Path: ${_controller.filePath}");
        await _refreshDuration();
        if (_audioDuration != null) {
          _trimEnd = _audioDuration! > 10 ? 10.0 : _audioDuration!;
        }
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future _refreshDuration() async {
    try {
      int durationF = await _controller.audioDuration();

      setState(() {
        _audioDuration = durationF / 1000;
        _trimEnd = _audioDuration!;
      });
    } catch (e) {
      log("Error getting audio furation $e");
    }
  }

  Future<void> _pickMergeFile() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result.isNotEmpty && result.single.path != null) {
      setState(() {
        _mergeFile = result.single.path;
      });
    }
  }

  Future<void> _pickWatermarkFile() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result.isNotEmpty && result.single.path != null) {
      setState(() {
        _watermarkFile = result.single.path;
      });
    }
  }

  Future<void> _pickCrossfadeFile() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result.isNotEmpty && result.single.path != null) {
      setState(() {
        _crossfadeFile = result.single.path;
      });
    }
  }

  Future<void> _applyTrim() async {
    if (_outputFile == null) return;
    await _applyFeature(() => _controller.trim(_trimStart, _trimEnd));
  }

  Future<void> _applyVolume() async {
    if (_outputFile == null) return;
    await _applyFeature(() => _controller.changeVolume(_volumeFactor));
  }

  Future<void> _applySpeed() async {
    if (_outputFile == null) return;
    await _applyFeature(() => _controller.changeSpeed(_speedFactor));
  }

  Future<void> _applyFadeIn() async {
    if (_outputFile == null) return;
    await _applyFeature(() => _controller.fadeIn(_fadeInDuration));
  }

  Future<void> _applyFadeOut() async {
    if (_outputFile == null) return;
    await _applyFeature(() => _controller.fadeOut(_fadeOutDuration));
  }

  Future<void> _applyConvert() async {
    if (_outputFile == null) return;
    await _applyFeature(() => _controller.convertTo(_convertFormat));
  }

  Future<void> _applyCompress() async {
    if (_outputFile == null) return;
    await _applyFeature(() => _controller.compress());
  }

  Future<void> _applyMerge() async {
    if (_outputFile == null || _mergeFile == null) return;
    await _applyFeature(() => _controller.mergeAudios([_mergeFile!]));
  }

  Future<void> _applyWatermark() async {
    if (_outputFile == null || _watermarkFile == null) return;
    await _applyFeature(
        () => _controller.addWaterMark(_watermarkFile!, _watermarkAtStart));
  }

  Future<void> _applyCrossfade() async {
    if (_outputFile == null || _crossfadeFile == null) return;
    await _applyFeature(
        () => _controller.crossFade(_crossfadeFile!, _crossfadeDuration));
  }

  Future<void> _handleUndo() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final success = await _controller.undo();
      if (success) {
        setState(() {
          _outputFile = _controller.filePath;
          _successMessage = 'Undo successful!';
          _audioDuration = null;
        });
        await _refreshDuration();
      } else {
        setState(() {
          _errorMessage = 'Nothing to undo';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during undo: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _applyFeature(Future<void> Function() feature) async {
    // Use a unique tag to filter in the IDE
    const String tag = 'AUDIO_EDITOR';

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final startTime = DateTime.now();

    // ┌── START LOG ──┐
    dev.log('┌──────────────────────────────────────────────────────────',
        name: tag);
    dev.log('│ 🚀 INITIATING FEATURE', name: tag);
    dev.log('│ Started at: ${startTime.toIso8601String()}', name: tag);
    dev.log('├──────────────────────────────────────────────────────────',
        name: tag);

    try {
      await feature();

      final duration = DateTime.now().difference(startTime);

      setState(() {
        _outputFile = _controller.filePath;
        _successMessage = 'Feature applied successfully!';
        _audioDuration = null;
      });

      // Success Block
      dev.log('│ ✅ SUCCESS', name: tag);
      dev.log('│ Execution Time: ${duration.inMilliseconds}ms', name: tag);
      dev.log('│ Output Path: ${_controller.filePath ?? "No file generated"}',
          name: tag);
      dev.log('└──────────────────────────────────────────────────────────',
          name: tag);
    } catch (e, stack) {
      // Error Block
      dev.log('│ ❌ ERROR DETECTED', name: tag);
      dev.log('│ Message: $e', name: tag);
      dev.log('├──────────────────────────────────────────────────────────',
          name: tag);
      dev.log('│ 🔍 STACK TRACE:', name: tag);

      // Log the stack trace separately to keep it readable
      dev.log(stack.toString(), name: tag);

      dev.log('└──────────────────────────────────────────────────────────',
          name: tag);

      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controller Demo')),
      body: _selectedFile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _pickFile,
                    icon: const Icon(Icons.audio_file),
                    label: const Text('Pick Audio File'),
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Undo Button
                  if (_controller.canUndo)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.undo, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit History (${_controller.editedAudioFiles.length} edits)',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _handleUndo,
                              icon: const Icon(Icons.undo),
                              label: const Text('Undo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_controller.canUndo) const SizedBox(height: 16),

                  // Audio Player
                  GestureDetector(
                    onTap: () {
                      _refreshDuration();
                    },
                    child: Icon(Icons.refresh),
                  ),

                  if (_outputFile != null)
                    AudioPlayerWidget(
                      filePath: _outputFile!,
                      label: 'Current Audio',
                    ),
                  const SizedBox(height: 16),

                  // Trim Section
                  _buildFeatureCard(
                    title: 'Trim Audio',
                    icon: Icons.content_cut,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                      'Start: ${_trimStart.toStringAsFixed(1)}s'),
                                  Slider(
                                    value: _trimStart,
                                    min: 0.0,
                                    max: _audioDuration ?? 100.0,
                                    divisions: (_audioDuration ?? 100).toInt(),
                                    onChanged: (value) {
                                      setState(() {
                                        _trimStart = value;
                                        if (_trimEnd <= _trimStart) {
                                          _trimEnd = _trimStart + 1;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  Text('End: ${_trimEnd.toStringAsFixed(1)}s'),
                                  Slider(
                                    value: _trimEnd,
                                    min: _trimStart + 1,
                                    max: _audioDuration ?? 100.0,
                                    divisions: (_audioDuration ?? 100).toInt(),
                                    onChanged: (value) {
                                      setState(() {
                                        _trimEnd = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _loading ? null : _applyTrim,
                          child: const Text('Apply Trim'),
                        ),
                      ],
                    ),
                  ),

                  // Volume Section
                  _buildFeatureCard(
                    title: 'Change Volume',
                    icon: Icons.volume_up,
                    child: Column(
                      children: [
                        Text(
                            'Volume: ${(_volumeFactor * 100).toStringAsFixed(0)}%'),
                        Slider(
                          value: _volumeFactor,
                          min: 0.0,
                          max: 2.0,
                          divisions: 40,
                          onChanged: (value) {
                            setState(() {
                              _volumeFactor = value;
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: _loading ? null : _applyVolume,
                          child: const Text('Apply Volume Change'),
                        ),
                      ],
                    ),
                  ),

                  // Speed Section
                  _buildFeatureCard(
                    title: 'Change Speed',
                    icon: Icons.speed,
                    child: Column(
                      children: [
                        Text('Speed: ${_speedFactor.toStringAsFixed(2)}x'),
                        Slider(
                          value: _speedFactor,
                          min: 0.5,
                          max: 2.0,
                          divisions: 30,
                          onChanged: (value) {
                            setState(() {
                              _speedFactor = value;
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: _loading ? null : _applySpeed,
                          child: const Text('Apply Speed Change'),
                        ),
                      ],
                    ),
                  ),

                  // Fade In Section
                  _buildFeatureCard(
                    title: 'Fade In',
                    icon: Icons.trending_up,
                    child: Column(
                      children: [
                        Text(
                            'Duration: ${_fadeInDuration.toStringAsFixed(1)}s'),
                        Slider(
                          value: _fadeInDuration,
                          min: 0.1,
                          max: 10.0,
                          divisions: 99,
                          onChanged: (value) {
                            setState(() {
                              _fadeInDuration = value;
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: _loading ? null : _applyFadeIn,
                          child: const Text('Apply Fade In'),
                        ),
                      ],
                    ),
                  ),

                  // Fade Out Section
                  _buildFeatureCard(
                    title: 'Fade Out',
                    icon: Icons.trending_down,
                    child: Column(
                      children: [
                        Text(
                            'Duration: ${_fadeOutDuration.toStringAsFixed(1)}s'),
                        Slider(
                          value: _fadeOutDuration,
                          min: 0.1,
                          max: 10.0,
                          divisions: 99,
                          onChanged: (value) {
                            setState(() {
                              _fadeOutDuration = value;
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: _loading ? null : _applyFadeOut,
                          child: const Text('Apply Fade Out'),
                        ),
                      ],
                    ),
                  ),

                  // Convert Section
                  _buildFeatureCard(
                    title: 'Convert Format',
                    icon: Icons.transform,
                    child: Column(
                      children: [
                        DropdownButton<String>(
                          value: _convertFormat,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: '.mp3', child: Text('MP3')),
                            DropdownMenuItem(value: '.wav', child: Text('WAV')),
                            DropdownMenuItem(value: '.m4a', child: Text('M4A')),
                            DropdownMenuItem(value: '.aac', child: Text('AAC')),
                            DropdownMenuItem(value: '.ogg', child: Text('OGG')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _convertFormat = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loading ? null : _applyConvert,
                          child: const Text('Convert'),
                        ),
                      ],
                    ),
                  ),

                  // Compress Section
                  _buildFeatureCard(
                    title: 'Compress Audio',
                    icon: Icons.compress,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _applyCompress,
                      child: const Text('Compress (96k bitrate)'),
                    ),
                  ),

                  // Merge Section
                  _buildFeatureCard(
                    title: 'Merge Audios',
                    icon: Icons.merge_type,
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _pickMergeFile,
                          icon: const Icon(Icons.audio_file),
                          label: Text(_mergeFile == null
                              ? 'Pick File to Merge'
                              : 'File Selected'),
                        ),
                        if (_mergeFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _mergeFile!.split('/').last,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loading ? null : _applyMerge,
                            child: const Text('Apply Merge'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Watermark Section
                  _buildFeatureCard(
                    title: 'Add Watermark',
                    icon: Icons.water_drop,
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _pickWatermarkFile,
                          icon: const Icon(Icons.audio_file),
                          label: Text(_watermarkFile == null
                              ? 'Pick Watermark File'
                              : 'File Selected'),
                        ),
                        if (_watermarkFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _watermarkFile!.split('/').last,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text('Place at start'),
                            value: _watermarkAtStart,
                            onChanged: (value) {
                              setState(() {
                                _watermarkAtStart = value ?? true;
                              });
                            },
                          ),
                          ElevatedButton(
                            onPressed: _loading ? null : _applyWatermark,
                            child: const Text('Apply Watermark'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Crossfade Section
                  _buildFeatureCard(
                    title: 'Crossfade',
                    icon: Icons.blur_on,
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _pickCrossfadeFile,
                          icon: const Icon(Icons.audio_file),
                          label: Text(_crossfadeFile == null
                              ? 'Pick Next Audio'
                              : 'File Selected'),
                        ),
                        if (_crossfadeFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _crossfadeFile!.split('/').last,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Duration: ${_crossfadeDuration.toStringAsFixed(1)}s'),
                          Slider(
                            value: _crossfadeDuration,
                            min: 0.1,
                            max: 10.0,
                            divisions: 99,
                            onChanged: (value) {
                              setState(() {
                                _crossfadeDuration = value;
                              });
                            },
                          ),
                          ElevatedButton(
                            onPressed: _loading ? null : _applyCrossfade,
                            child: const Text('Apply Crossfade'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_loading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String filePath;
  final String label;

  const AudioPlayerWidget({
    super.key,
    required this.filePath,
    this.label = 'Audio',
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _initPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _position = position;
      });
    });
  }

  Future<void> _initPlayer() async {
    await _audioPlayer.setSourceDeviceFile(widget.filePath);
    final duration = await _audioPlayer.getDuration();
    if (duration != null) {
      setState(() {
        _duration = duration;
      });
    }
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    await _audioPlayer.setSourceDeviceFile(widget.filePath);
    setState(() {
      _position = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds.toDouble()
                  : 0.0,
              max: _duration.inMilliseconds > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _playPause,
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: _stop,
                    ),
                  ],
                ),
                Text(_formatDuration(_duration)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
