import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'analysis_error.dart';

class ColorAnalyzer {
  static const Map<String, Color> _knownColors = {
    'Black': Colors.black,
    'White': Colors.white,
    'Gray': Colors.grey,
    'Navy': Color(0xFF1D3557),
    'Blue': Colors.blue,
    'Teal': Colors.teal,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Orange': Colors.orange,
    'Red': Colors.red,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
    'Brown': Color(0xFF8D6E63),
    'Beige': Color(0xFFF5E6C4),
    'Tan': Color(0xFFD2B48C),
  };

  Future<List<String>> extractDominantColors(Uint8List bytes, {int maxColors = 3}) async {
    if (bytes.isEmpty) {
      throw const AnalysisError.invalidImage();
    }

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        maximumColorCount: maxColors + 4,
      );

      final candidates = <Color?>[
        generator.dominantColor?.color,
        generator.vibrantColor?.color,
        generator.lightVibrantColor?.color,
        generator.mutedColor?.color,
        generator.lightMutedColor?.color,
        generator.darkMutedColor?.color,
      ].whereType<Color>().toList();

      final names = <String>[];
      for (final color in candidates) {
        final name = _nearestColorName(color);
        if (!names.contains(name)) {
          names.add(name);
        }
        if (names.length >= maxColors) break;
      }

      if (names.isEmpty) {
        throw const AnalysisError.colorExtractionFailed();
      }

      return names;
    } catch (_) {
      throw const AnalysisError.colorExtractionFailed();
    }
  }

  String _nearestColorName(Color color) {
    String bestName = 'Blue';
    double bestDistance = double.infinity;

    for (final entry in _knownColors.entries) {
      final distance = _colorDistance(color, entry.value);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestName = entry.key;
      }
    }

    return bestName;
  }

  double _colorDistance(Color a, Color b) {
    final dr = a.red - b.red;
    final dg = a.green - b.green;
    final db = a.blue - b.blue;
    return (dr * dr + dg * dg + db * db).toDouble();
  }
}