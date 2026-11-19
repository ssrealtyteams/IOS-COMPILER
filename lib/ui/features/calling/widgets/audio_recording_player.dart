import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

class AudioRecordingPlayer extends StatefulWidget {
  const AudioRecordingPlayer({
    super.key,
    this.filePath,
    this.s3Url,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  final String? filePath;
  final String? s3Url;
  final bool isUploading;
  final double uploadProgress;

  @override
  State<AudioRecordingPlayer> createState() => _AudioRecordingPlayerState();
}

class _AudioRecordingPlayerState extends State<AudioRecordingPlayer> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _speed = 1.0;
  String? _error;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<File?> _resolvePlayableFile() async {
    try {
      Directory targetDir;
      try {
        final extDirs = await getExternalCacheDirectories();
        targetDir = (extDirs != null && extDirs.isNotEmpty) ? extDirs.first : await getTemporaryDirectory();
      } catch (_) {
        targetDir = await getTemporaryDirectory();
      }

      // 1. If S3 URL is provided, fetch via HTTP GET and cache locally to avoid ExoPlayer 416 Range issues
      if (widget.s3Url != null && widget.s3Url!.isNotEmpty) {
        final rawFileName = widget.s3Url!.split('/').last.split('?').first;
        final cleanFileName = rawFileName.isNotEmpty ? rawFileName : 'cached_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final cachedFile = File('${targetDir.path}/$cleanFileName');

        if (await cachedFile.exists() && (await cachedFile.length()) > 0) {
          debugPrint('🎧 [AudioPlayer] Using cached S3 recording: ${cachedFile.path} (${await cachedFile.length()} bytes)');
          return cachedFile;
        }

        debugPrint('🎧 [AudioPlayer] Downloading recording from S3: ${widget.s3Url}');
        final dio = Dio();
        final response = await dio.get<List<int>>(
          widget.s3Url!,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Accept': '*/*'},
          ),
        );

        if (response.statusCode == 200 && response.data != null && response.data!.isNotEmpty) {
          await cachedFile.writeAsBytes(response.data!, flush: true);
          debugPrint('✅ [AudioPlayer] Downloaded from S3 and cached: ${cachedFile.path} (${response.data!.length} bytes)');
          return cachedFile;
        } else {
          debugPrint('🚨 [AudioPlayer:ERROR] S3 HTTP GET returned status: ${response.statusCode}');
        }
      }

      // 2. If local recording file exists, copy to cache directory so ExoPlayer can open without scoped storage sandbox issues
      if (widget.filePath != null && widget.filePath!.isNotEmpty) {
        final localFile = File(widget.filePath!);
        if (await localFile.exists() && (await localFile.length()) > 0) {
          final fileName = localFile.path.split(Platform.pathSeparator).last;
          final cachedLocalFile = File('${targetDir.path}/$fileName');
          if (!await cachedLocalFile.exists() || (await cachedLocalFile.length()) != (await localFile.length())) {
            final bytes = await localFile.readAsBytes();
            await cachedLocalFile.writeAsBytes(bytes, flush: true);
          }
          debugPrint('🎧 [AudioPlayer] Using cached local recording: ${cachedLocalFile.path} (${await cachedLocalFile.length()} bytes)');
          return cachedLocalFile;
        } else {
          debugPrint('🚨 [AudioPlayer:ERROR] Local file does not exist or empty: ${widget.filePath}');
        }
      }
    } catch (e, stack) {
      debugPrint('🚨 [AudioPlayer:ERROR] Failed resolving audio file: $e');
      debugPrint('🚨 [AudioPlayer:STACK] $stack');
    }
    return null;
  }

  Future<void> _initAndPlay() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _player ??= AudioPlayer();

      _player!.durationStream.listen((d) {
        if (mounted && d != null) {
          setState(() => _duration = d);
        }
      });

      _player!.positionStream.listen((p) {
        if (mounted) {
          setState(() => _position = p);
        }
      });

      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing && state.processingState != ProcessingState.completed;
            _isLoading = state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering;

            if (state.processingState == ProcessingState.completed) {
              _position = Duration.zero;
              _player?.seek(Duration.zero);
              _player?.pause();
            }
          });
        }
      });

      final playableFile = await _resolvePlayableFile();
      if (playableFile == null) {
        const msg = 'Recording not found on S3 or device';
        debugPrint('🚨 [AudioPlayer:ERROR] $msg (s3: ${widget.s3Url}, local: ${widget.filePath})');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = msg;
          });
        }
        return;
      }

      debugPrint('🎧 [AudioPlayer] Setting file path in ExoPlayer: ${playableFile.path}');
      try {
        await _player!.setAudioSource(AudioSource.uri(Uri.file(playableFile.path)));
      } catch (err) {
        debugPrint('⚠️ [AudioPlayer] setAudioSource failed: $err, trying setFilePath');
        await _player!.setFilePath(playableFile.path);
      }
      debugPrint('✅ [AudioPlayer] File loaded successfully! Duration: ${_player!.duration}');
      
      debugPrint('▶️ [AudioPlayer] Starting playback...');
      await _player!.play();
      debugPrint('✅ [AudioPlayer] Playback active!');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stack) {
      debugPrint('🚨 [AudioPlayer:FATAL] Playback exception: $e');
      debugPrint('🚨 [AudioPlayer:STACK] $stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  Future<void> _togglePlay() async {
    if (_player == null || _error != null) {
      await _initAndPlay();
      return;
    }

    if (_isPlaying) {
      await _player!.pause();
    } else {
      if (_player!.processingState == ProcessingState.completed) {
        await _player!.seek(Duration.zero);
      }
      await _player!.play();
    }
  }

  void _cycleSpeed() {
    final newSpeed = switch (_speed) {
      1.0 => 1.5,
      1.5 => 2.0,
      _ => 1.0,
    };
    _player?.setSpeed(newSpeed);
    setState(() => _speed = newSpeed);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final hasSource = (widget.filePath != null && widget.filePath!.isNotEmpty) ||
        (widget.s3Url != null && widget.s3Url!.isNotEmpty);

    if (!hasSource && !widget.isUploading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9F2),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: const Color(0xFFE8D5B5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6914).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, size: 15, color: Color(0xFF8B6914)),
              ),
              const SizedBox(width: 8),
              Text(
                'Voice Recording',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3E2723),
                ),
              ),
              const Spacer(),
              if (widget.isUploading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withAlpha(80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.orange),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'AWS S3 Uploading...',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (widget.s3Url != null && widget.s3Url!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_rounded, size: 11, color: Color(0xFF2E7D32)),
                      SizedBox(width: 3),
                      Text(
                        'AWS S3',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Player controls row
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.brown, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _initAndPlay,
                    child: const Text(
                      'Retry',
                      style: TextStyle(fontSize: 10, color: AppColors.ssGoldDark, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            )
          else
            Row(
              children: [
                // Play / Pause Button
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.ssGoldDark,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ssGoldDark.withAlpha(50),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Scrubber / Slider
                Expanded(
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: AppColors.ssGoldDark,
                          inactiveTrackColor: const Color(0xFFE8D5B5),
                          thumbColor: AppColors.ssGoldDark,
                        ),
                        child: Slider(
                          value: _position.inMilliseconds
                              .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1)
                              .toDouble(),
                          max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                          onChanged: (val) {
                            _player?.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Speed button
                GestureDetector(
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE8D5B5)),
                    ),
                    child: Text(
                      '${_speed.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
