import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/photo_quality_vision_service.dart';
import 'package:image/image.dart' as img;

enum PhotoSourceType { camera, gallery }

class PhotoAnalysisScreen extends StatefulWidget {
  static const int minWidth = 300;
  static const int minHeight = 300;
  static const double minObjectRatio = 0.4; // 40%
  final XFile photo;
  final VoidCallback onKeep;
  final void Function(BuildContext context) onRetake;
  final PhotoSourceType sourceType;

  const PhotoAnalysisScreen({
    super.key,
    required this.photo,
    required this.onRetake,
    required this.onKeep,
    required this.sourceType,
  });

  @override
  State<PhotoAnalysisScreen> createState() => _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends State<PhotoAnalysisScreen> {
  double? objectRatio;
  bool loading = true;
  List<String> suggestions = [];
  String blurFeedback = '';
  String exposureFeedback = '';
  Color blurColor = Colors.green;
  Color exposureColor = Colors.green;
  IconData blurIcon = Icons.check_circle_rounded;
  IconData exposureIcon = Icons.check_circle_rounded;
  VisionPhotoQualityResult? visionResult;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    setState(() {
      loading = true;
    });
    // Run vision analysis
    final visionService = VisionPhotoQualityService();
    final result = await visionService.analyzePhoto(widget.photo);
    setState(() {
      visionResult = result;
    });
    await _analyzeFraming();
  }

  Future<void> _analyzeFraming() async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final bytes = await File(widget.photo.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        // Improved framing: sample center and border, estimate object area by color difference
        final w = decoded.width, h = decoded.height;
        final center = decoded.getPixel(w ~/ 2, h ~/ 2);
        int objectCount = 0, totalCount = 0;
        for (int y = 0; y < h; y += (h ~/ 40).clamp(1, 20)) {
          for (int x = 0; x < w; x += (w ~/ 40).clamp(1, 20)) {
            final pixel = decoded.getPixel(x, y);
            // If color distance from center is small, count as object
            if (_colorDistance(pixel, center) < 60) {
              objectCount++;
            }
            totalCount++;
          }
        }
        setState(() {
          objectRatio = totalCount > 0 ? objectCount / totalCount : null;
        });
      }
    } catch (_) {
      setState(() {
        objectRatio = null;
      });
    }
    _analyzeFeedback();
  }

  int _colorDistance(int a, int b) {
    int ar = (a >> 16) & 0xFF, ag = (a >> 8) & 0xFF, ab = a & 0xFF;
    int br = (b >> 16) & 0xFF, bg = (b >> 8) & 0xFF, bb = b & 0xFF;
    return ((ar - br).abs() + (ag - bg).abs() + (ab - bb).abs());
  }

  void _analyzeFeedback() {
    suggestions.clear();
    final result = visionResult;
    if (result == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    if (result.isBlurry || result.blurLikelihood > 0.15) {
      blurFeedback = 'Blurry';
      blurColor = Colors.red;
      blurIcon = Icons.blur_on_rounded;
      suggestions.add('Try holding the camera steady or cleaning the lens.');
    } else if (result.blurLikelihood > 0.08) {
      blurFeedback = 'Borderline';
      blurColor = Colors.orange;
      blurIcon = Icons.blur_circular_rounded;
      suggestions.add('Photo may be slightly blurry.');
    } else {
      blurFeedback = 'Sharp';
      blurColor = Colors.green;
      blurIcon = Icons.check_circle_rounded;
    }
    if (result.isUnderexposed || result.isOverexposed || result.exposureLikelihood < 0.25 || result.exposureLikelihood > 0.8) {
      exposureFeedback = result.isUnderexposed || result.exposureLikelihood < 0.25 ? 'Too Dark' : 'Too Bright';
      exposureColor = Colors.red;
      exposureIcon = Icons.warning_amber_rounded;
      if (result.isUnderexposed || result.exposureLikelihood < 0.25) {
        suggestions.add('Try taking the photo in better lighting.');
      }
      if (result.isOverexposed || result.exposureLikelihood > 0.8) {
        suggestions.add('Avoid too much light or glare.');
      }
    } else if (result.exposureLikelihood < 0.35 || result.exposureLikelihood > 0.7) {
      exposureFeedback = 'Borderline';
      exposureColor = Colors.orange;
      exposureIcon = Icons.light_mode_rounded;
      suggestions.add('Lighting could be improved.');
    } else {
      exposureFeedback = 'Good';
      exposureColor = Colors.green;
      exposureIcon = Icons.check_circle_rounded;
    }
    // Framing suggestion
    if (objectRatio != null && objectRatio! < PhotoAnalysisScreen.minObjectRatio) {
      suggestions.add('Try zooming in or getting closer so the item fills more of the photo.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('Try changing the lighting or make sure the photo is clear.');
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Photo Analysis'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Analyzing photo...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.photo.path),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (visionResult != null)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(blurIcon, color: blurColor, size: 28),
                                const SizedBox(width: 12),
                                Text('Blur:', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text(blurFeedback, style: TextStyle(color: blurColor, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('${(visionResult!.blurLikelihood * 100).toStringAsFixed(0)}%', style: TextStyle(color: blurColor)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(exposureIcon, color: exposureColor, size: 28),
                                const SizedBox(width: 12),
                                Text('Exposure:', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text(exposureFeedback, style: TextStyle(color: exposureColor, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('${(visionResult!.exposureLikelihood * 100).toStringAsFixed(0)}%', style: TextStyle(color: exposureColor)),
                              ],
                            ),
                            if (objectRatio != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      (objectRatio! < PhotoAnalysisScreen.minObjectRatio)
                                          ? Icons.crop_5_4_rounded
                                          : Icons.check_circle_rounded,
                                      color: (objectRatio! < PhotoAnalysisScreen.minObjectRatio)
                                          ? Colors.orange
                                          : Colors.green,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Framing:', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Text(
                                      objectRatio! < PhotoAnalysisScreen.minObjectRatio ? 'Zoom in' : 'Good',
                                      style: TextStyle(
                                        color: objectRatio! < PhotoAnalysisScreen.minObjectRatio ? Colors.orange : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${(objectRatio! * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: objectRatio! < PhotoAnalysisScreen.minObjectRatio ? Colors.orange : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Card(
                    color: Colors.yellow[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 6),
                          ...suggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.tips_and_updates_rounded, size: 18, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(child: Text(s, style: const TextStyle(color: Colors.black87))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  if (visionResult != null && visionResult!.error != null) ...[
                    const SizedBox(height: 8),
                    Text('Error: ${visionResult!.error}', style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.onRetake(context),
                    child: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onKeep,
                    child: const Text('Keep'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

