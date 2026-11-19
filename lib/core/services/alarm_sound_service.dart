import 'dart:async';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logger/logger.dart';

class AlarmSoundService {
  static final Logger _logger = Logger();
  static AudioPlayer? _player;
  static Timer? _vibrationTimer;
  static bool _isPlaying = false;
  static bool _isSilenced = false;

  static bool get isPlaying => _isPlaying;
  static bool get isSilenced => _isSilenced;

  /// Initialize player and audio session for Android alarm stream
  static Future<void> init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.alarm,
          flags: AndroidAudioFlags.audibilityEnforced,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ));

      _player ??= AudioPlayer();
      await _player!.setAsset('assets/audio/alarm_sound.wav');
      await _player!.setLoopMode(LoopMode.one);
      await _player!.setVolume(1.0);
      _logger.i('✅ AlarmSoundService initialized with Alarm audio stream');
    } catch (e) {
      _logger.e('Failed to init AlarmSoundService: $e');
    }
  }

  /// Start ringing alarm sound continuously and vibrate phone
  static Future<void> startRinging() async {
    if (_isPlaying) return;
    _isPlaying = true;
    _isSilenced = false;
    _logger.i('🔔 Alarm started ringing!');

    try {
      final session = await AudioSession.instance;
      await session.setActive(true);

      _player ??= AudioPlayer();
      await _player!.setAsset('assets/audio/alarm_sound.wav');
      await _player!.setLoopMode(LoopMode.one);
      await _player!.setVolume(1.0);
      await _player!.seek(Duration.zero);
      await _player!.play();
    } catch (e) {
      _logger.e('Error playing alarm audio: $e');
    }

    // Continuous alarm vibration pattern (vibrates in a pulsing rhythm)
    _vibrationTimer?.cancel();
    HapticFeedback.vibrate();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!_isPlaying || _isSilenced) {
        timer.cancel();
        return;
      }
      HapticFeedback.vibrate();
    });
  }

  /// Silence alarm sound & vibration (e.g. on volume key press) while keeping alarm screen open
  static Future<void> silenceRinging() async {
    _isSilenced = true;
    _isPlaying = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      if (_player != null) {
        await _player!.stop();
        await _player!.seek(Duration.zero);
      }
      _logger.i('🔕 Alarm sound silenced');
    } catch (e) {
      _logger.e('Error silencing alarm: $e');
    }
  }

  /// Stop alarm ringing and vibration immediately
  static Future<void> stopRinging() async {
    _isPlaying = false;
    _isSilenced = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      if (_player != null) {
        await _player!.stop();
        await _player!.seek(Duration.zero);
      }
      _logger.i('🔕 Alarm ringing stopped');
    } catch (e) {
      _logger.e('Error stopping alarm audio: $e');
    }
  }
}
