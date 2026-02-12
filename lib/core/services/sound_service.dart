import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sound types available in the app
enum SoundType {
  hatch,
  levelUp,
  eggReceived,
  petTap,
  goalComplete,
  buttonTap,
}

/// Service for playing sound effects
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  bool _initialized = false;

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Set up audio player for short sound effects
      await _player.setReleaseMode(ReleaseMode.stop);
      _initialized = true;
      debugPrint('SoundService initialized');
    } catch (e) {
      debugPrint('SoundService initialization failed: $e');
    }
  }

  /// Enable or disable sounds
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  bool get soundEnabled => _soundEnabled;

  /// Play a sound effect
  Future<void> play(SoundType type) async {
    if (!_soundEnabled || !_initialized) return;

    try {
      // Use generated tones since we don't have audio files
      // These are simple beep-like sounds using the ToneGenerator approach
      final frequency = _getFrequency(type);
      final duration = _getDuration(type);
      
      // For web, we'll use a data URL with a simple tone
      // This is a workaround since audioplayers needs actual audio files
      await _playTone(frequency, duration);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  double _getFrequency(SoundType type) {
    switch (type) {
      case SoundType.hatch:
        return 880.0; // A5 - exciting high note
      case SoundType.levelUp:
        return 1046.5; // C6 - triumphant
      case SoundType.eggReceived:
        return 659.3; // E5 - pleasant
      case SoundType.petTap:
        return 523.3; // C5 - soft
      case SoundType.goalComplete:
        return 784.0; // G5 - celebratory
      case SoundType.buttonTap:
        return 440.0; // A4 - neutral
    }
  }

  int _getDuration(SoundType type) {
    switch (type) {
      case SoundType.hatch:
        return 500;
      case SoundType.levelUp:
        return 400;
      case SoundType.eggReceived:
        return 300;
      case SoundType.petTap:
        return 150;
      case SoundType.goalComplete:
        return 600;
      case SoundType.buttonTap:
        return 100;
    }
  }

  Future<void> _playTone(double frequency, int durationMs) async {
    // Generate a simple sine wave tone as a data URL
    // This works on web and mobile
    try {
      final sampleRate = 44100;
      final numSamples = (sampleRate * durationMs / 1000).round();
      final samples = List<int>.generate(numSamples, (i) {
        final t = i / sampleRate;
        // Sine wave with envelope (fade in/out)
        final envelope = _envelope(i, numSamples);
        final sample = (envelope * 32767 * 0.5 * _sine(frequency * t)).round();
        return sample.clamp(-32768, 32767);
      });

      // Create WAV file in memory
      final wavBytes = _createWavBytes(samples, sampleRate);
      
      // Play using BytesSource
      await _player.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('Error generating tone: $e');
    }
  }

  double _sine(double t) => _sinApprox(t * 2 * 3.14159265359);
  
  // Fast sine approximation
  double _sinApprox(double x) {
    // Normalize to -pi to pi
    x = x % (2 * 3.14159265359);
    if (x > 3.14159265359) x -= 2 * 3.14159265359;
    if (x < -3.14159265359) x += 2 * 3.14159265359;
    
    // Parabola approximation
    const b = 4 / 3.14159265359;
    const c = -4 / (3.14159265359 * 3.14159265359);
    double y = b * x + c * x * x.abs();
    
    // Extra precision
    const p = 0.225;
    y = p * (y * y.abs() - y) + y;
    
    return y;
  }

  double _envelope(int sample, int totalSamples) {
    // Attack-decay envelope
    final attackSamples = totalSamples * 0.1;
    final decaySamples = totalSamples * 0.3;
    
    if (sample < attackSamples) {
      return sample / attackSamples;
    } else if (sample > totalSamples - decaySamples) {
      return (totalSamples - sample) / decaySamples;
    }
    return 1.0;
  }

  Uint8List _createWavBytes(List<int> samples, int sampleRate) {
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = samples.length * blockAlign;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    var offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // 'R'
    buffer.setUint8(offset++, 0x49); // 'I'
    buffer.setUint8(offset++, 0x46); // 'F'
    buffer.setUint8(offset++, 0x46); // 'F'
    buffer.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // 'W'
    buffer.setUint8(offset++, 0x41); // 'A'
    buffer.setUint8(offset++, 0x56); // 'V'
    buffer.setUint8(offset++, 0x45); // 'E'

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // 'f'
    buffer.setUint8(offset++, 0x6D); // 'm'
    buffer.setUint8(offset++, 0x74); // 't'
    buffer.setUint8(offset++, 0x20); // ' '
    buffer.setUint32(offset, 16, Endian.little); // Subchunk1Size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // AudioFormat (PCM)
    offset += 2;
    buffer.setUint16(offset, numChannels, Endian.little);
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, byteRate, Endian.little);
    offset += 4;
    buffer.setUint16(offset, blockAlign, Endian.little);
    offset += 2;
    buffer.setUint16(offset, bitsPerSample, Endian.little);
    offset += 2;

    // data chunk
    buffer.setUint8(offset++, 0x64); // 'd'
    buffer.setUint8(offset++, 0x61); // 'a'
    buffer.setUint8(offset++, 0x74); // 't'
    buffer.setUint8(offset++, 0x61); // 'a'
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Sample data
    for (final sample in samples) {
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// Play a sequence of tones (for hatch, level up celebrations)
  Future<void> playSequence(List<SoundType> types, {int delayMs = 150}) async {
    for (final type in types) {
      await play(type);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }

  /// Play hatch celebration (ascending tones)
  Future<void> playHatchCelebration() async {
    if (!_soundEnabled || !_initialized) return;
    
    // Play ascending happy tones
    await _playTone(523.3, 150); // C5
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(659.3, 150); // E5
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(784.0, 150); // G5
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(1046.5, 300); // C6
  }

  /// Play level up sound (quick ascending)
  Future<void> playLevelUp() async {
    if (!_soundEnabled || !_initialized) return;
    
    await _playTone(659.3, 100); // E5
    await Future.delayed(const Duration(milliseconds: 80));
    await _playTone(784.0, 100); // G5
    await Future.delayed(const Duration(milliseconds: 80));
    await _playTone(1046.5, 200); // C6
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}




