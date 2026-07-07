import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  // Initialize sound service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      // Set audio mode to play even in silent mode (Android)
      try {
        await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
        // Set volume to maximum
        await _audioPlayer.setVolume(1.0);
      } catch (e) {
        debugPrint("⚠️ Could not set audio mode: $e");
      }
      _isInitialized = true;
    }
  }

  // Play new order notification sound
  static Future<void> playNewOrderSound({int? duration}) async {
    try {
      await initialize();

      // Load asset as bytes to avoid case sensitivity issues
      List<String> pathsToTry = [
        'Assets/sounds/order.mp3',
        'Assets/Sounds/order.mp3',
        'sounds/order.mp3',
      ];

      ByteData? audioBytes;
      for (String path in pathsToTry) {
        try {
          audioBytes = await rootBundle.load(path);
          // debugPrint("✅ Found asset at: $path");
          break;
        } catch (e) {
          continue;
        }
      }

      if (audioBytes != null) {
        final Uint8List bytes = audioBytes.buffer.asUint8List();

        try {
          // Handle looping if duration is provided and greater than 0
          if (duration != null && duration > 0) {
            await _audioPlayer.setReleaseMode(ReleaseMode.loop);
            await _audioPlayer.play(BytesSource(bytes));

            // Schedule stop after duration
            Future.delayed(Duration(seconds: duration), () async {
              await stopSound();
              // Reset release mode for future non-looped plays
              await _audioPlayer.setReleaseMode(ReleaseMode.stop);
            });
          } else {
            // Play once
            await _audioPlayer.setReleaseMode(ReleaseMode.stop);
            await _audioPlayer.play(BytesSource(bytes));
          }

          debugPrint(
            "🔊 New order sound played (Duration: ${duration ?? 'Default'})",
          );
        } catch (e) {
          debugPrint("⚠️ Could not play sound from bytes: $e");
        }
      } else {
        debugPrint("⚠️ Sound file not found in asset bundle");
      }
    } catch (e) {
      debugPrint("❌ Error in sound service: $e");
    }
  }

  // Play sound from asset
  static Future<void> playSound(String assetPath) async {
    try {
      await initialize();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("❌ Error playing sound from $assetPath: $e");
    }
  }

  // Stop any currently playing sound
  static Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint("❌ Error stopping sound: $e");
    }
  }

  // Dispose resources
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint("❌ Error disposing sound service: $e");
    }
  }
}
