import 'dart:developer';

import 'package:example/audio_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:audio_editing_tool/audio_editing_tool.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // bool success = await openDownloadFolder();
  // if (success) {
  //   print('Download folder opened successfully.');
  // } else {
  //   print('Failed to open download folder.');
  // }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Editing Tool Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Audio Editing Tool Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AudioViewController(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Controller Demo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelperDemoPage(),
                  ),
                );
              },
              icon: const Icon(Icons.build),
              label: const Text('Helper Demo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to get audio duration
Future<double?> getAudioDuration(String filePath) async {
  try {
    final player = AudioPlayer();
    await player.setSourceDeviceFile(filePath);
    final duration = await player.getDuration();
    await player.dispose();
    return duration?.inSeconds.toDouble();
  } catch (e) {
    log('Error getting audio duration: $e');
    return null;
  }
}

// Audio Player Widget
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
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });
    _audioPlayer.onPositionChanged.listen((position) {
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

class HelperDemoPage extends StatefulWidget {
  const HelperDemoPage({super.key});

  @override
  State<HelperDemoPage> createState() => _HelperDemoPageState();
}

class _HelperDemoPageState extends State<HelperDemoPage> {
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
        _outputFile = _selectedFile;
        _audioDuration = await getAudioDuration(_selectedFile!);
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
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result =
        await AudioEditorHelper.trim(_outputFile!, _trimStart, _trimEnd);
    _handleResult(result);
  }

  Future<void> _applyVolume() async {
    if (_outputFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result =
        await AudioEditorHelper.changeVolume(_outputFile!, _volumeFactor);
    _handleResult(result);
  }

  Future<void> _applySpeed() async {
    if (_outputFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result =
        await AudioEditorHelper.changeSpeed(_outputFile!, _speedFactor);
    _handleResult(result);
  }

  Future<void> _applyFadeIn() async {
    if (_outputFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result =
        await AudioEditorHelper.fadeIn(_outputFile!, _fadeInDuration);
    _handleResult(result);
  }

  Future<void> _applyFadeOut() async {
    if (_outputFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result =
        await AudioEditorHelper.fadeOut(_outputFile!, _fadeOutDuration);
    _handleResult(result);
  }

  Future<void> _applyConvert() async {
    if (_outputFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result =
        await AudioEditorHelper.convertTo(_outputFile!, _convertFormat);
    _handleResult(result);
  }

  Future<void> _applyCompress() async {
    if (_outputFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result = await AudioEditorHelper.compress(_outputFile!);
    _handleResult(result);
  }

  Future<void> _applyMerge() async {
    if (_outputFile == null || _mergeFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result =
        await AudioEditorHelper.mergeAudios(_outputFile!, [_mergeFile!]);
    _handleResult(result);
  }

  Future<void> _applyWatermark() async {
    if (_outputFile == null || _watermarkFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result = await AudioEditorHelper.addWatermark(
        _outputFile!, _watermarkFile!, _watermarkAtStart);
    _handleResult(result);
  }

  Future<void> _applyCrossfade() async {
    if (_outputFile == null || _crossfadeFile == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    final result = await AudioEditorHelper.crossFade(
        _outputFile!, _crossfadeFile!, _crossfadeDuration);
    _handleResult(result);
  }

  void _handleResult((bool success, String result) result) {
    setState(() {
      _loading = false;
      if (result.$1) {
        _outputFile = result.$2;
        _successMessage = 'Feature applied successfully!';
        _errorMessage = null;
      } else {
        _errorMessage = 'Error: ${result.$2}';
        _successMessage = null;
      }
    });
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
      appBar: AppBar(title: const Text('Helper Demo')),
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
                  // Audio Player
                  if (_outputFile != null)
                    AudioPlayerWidget(
                      filePath: _outputFile!,
                      label: 'Current Audio',
                    ),
                  const SizedBox(height: 16),

                  // Trim Section
                  _buildFeatureCard(
                    context: context,
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
                    context: context,
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
                    context: context,
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
                    context: context,
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
                    context: context,
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
                    context: context,
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
                    context: context,
                    title: 'Compress Audio',
                    icon: Icons.compress,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _applyCompress,
                      child: const Text('Compress (96k bitrate)'),
                    ),
                  ),

                  // Merge Section
                  _buildFeatureCard(
                    context: context,
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
                    context: context,
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
                    context: context,
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
    required BuildContext context,
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
