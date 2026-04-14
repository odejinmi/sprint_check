import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sprint_check/sdk/face_detector_service.dart';
import 'package:sprint_check/sdk/face_painter.dart';
import 'package:sprintliveness/sprintliveness.dart';
import '../string.dart';
import '../theme/app'
    '_theme.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> with SingleTickerProviderStateMixin {
  final FaceDetectorService _faceService = FaceDetectorService();
  final ImagePicker _picker = ImagePicker();

  File? _image1;
  File? _image2;
  Size? _imageSize1;
  Size? _imageSize2;
  List<FaceDetectionResult> _results1 = [];
  List<FaceDetectionResult> _results2 = [];
  FaceComparisonResult? _comparisonResult;
  bool _isLoading = false;
  bool _modelsReady = false;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ringAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _initModels();
  }

  Future<void> _initModels() async {
    try {
      await _faceService.initialize();
      setState(() => _modelsReady = true);
    } catch (e) {
      setState(() => _error = 'Failed to initialize: $e');
    }

    final tempDir = await getTemporaryDirectory();

    dev.log('Liveness image received');
    final bytes = base64Decode(image1);
    var file = File('${tempDir.path}/liveness_face.jpg');
    await file.writeAsBytes(bytes);
    if (file == null) return;
    final decoded = await decodeImageFromList(await file.readAsBytes());
    final size = Size(decoded.width.toDouble(), decoded.height.toDouble());
    _image2 = file;
    _imageSize2 = size;
    _results2 = [];

    final bytes1 = base64Decode(image2);
    var file1 = File('${tempDir.path}/liveness_face1.jpg');
    await file1.writeAsBytes(bytes1);
    if (file1 == null) return;
    final decoded1 = await decodeImageFromList(await file1.readAsBytes());
    final size1 = Size(decoded1.width.toDouble(), decoded1.height.toDouble());
    _image1 = file1;
    _imageSize1 = size1;
    _results2 = [];
    if (!mounted)  return;
    setState(() {

    });
  }

  final _sprintlivenessPlugin = Sprintliveness();
  Future<void> _pickImage(int imageIndex) async {
    final source = await _showPickerDialog();
    if (source == null) return;

    try {
      File? file;
      // if (imageIndex == 1) {
        final picked = await _picker.pickImage(source: source, maxWidth: 1200);
        if (picked == null) return;
        file = File(picked.path);
      // } else {
      //   final livenessResult = await _sprintlivenessPlugin.startLivenessCheck(context);
      //   if (livenessResult == null || livenessResult.image == null) {
      //     return;
      //   }
      //
      //   dev.log('Liveness image received');
      //   final bytes = base64Decode(livenessResult.image!);
      //   final tempDir = await getTemporaryDirectory();
      //   file = File('${tempDir.path}/liveness_face2.jpg');
      //   await file.writeAsBytes(bytes);
      // }

      if (file == null) return;

      final decoded = await decodeImageFromList(await file.readAsBytes());
      final size = Size(decoded.width.toDouble(), decoded.height.toDouble());

      setState(() {
        if (imageIndex == 1) {
          _image1 = file;
          _imageSize1 = size;
          _results1 = [];
        } else {
          _image2 = file;
          _imageSize2 = size;
          _results2 = [];
        }
        _comparisonResult = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _compareFaces() async {
    if (_image1 == null || _image2 == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _comparisonResult = null;
      _results1 = [];
      _results2 = [];
    });

    try {
      final input1 = InputImage.fromFilePath(_image1!.path);
      final input2 = InputImage.fromFilePath(_image2!.path);

      final results = await Future.wait([
        _faceService.detectFaces(input1),
        _faceService.detectFaces(input2),
      ]);

      _results1 = results[0];
      _results2 = results[1];

      if (_results1.isEmpty || _results2.isEmpty) {
        setState(() {
          _error = 'No face detected in ${_results1.isEmpty ? "Image 1" : ""}${_results1.isEmpty && _results2.isEmpty ? " and " : ""}${_results2.isEmpty ? "Image 2" : ""}. Use images with clear faces.';
        });
        return;
      }

      final emb1 = _results1[0].faceEmbedding;
      final emb2 = _results2[0].faceEmbedding;

      if (emb1 != null && emb2 != null) {
        final comparison = FaceDetectorService.compareFaces(emb1, emb2);
        setState(() => _comparisonResult = comparison);
        _animController.forward(from: 0);
      }
    } catch (e) {
      setState(() => _error = 'Comparison failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _reset() {
    setState(() {
      _image1 = null;
      _image2 = null;
      _results1 = [];
      _results2 = [];
      _comparisonResult = null;
      _error = null;
    });
    _animController.reset();
  }

  @override
  void dispose() {
    _faceService.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const GradientText('⚖️ Face Comparison',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.bgPrimary,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload two images to compare faces and determine similarity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),

            if (!_modelsReady)
              GlowCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentPrimary)),
                    const SizedBox(width: 12),
                    const Text('Loading AI Models...', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            if (_modelsReady) ...[
              // Two image slots
              Row(
                children: [
                  Expanded(child: _buildImageSlot(1, _image1, _imageSize1, _results1)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildImageSlot(2, _image2, _imageSize2, _results2)),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: 'Compare Faces',
                      icon: Icons.compare,
                      isLoading: _isLoading,
                      onPressed: (_image1 != null && _image2 != null && !_isLoading)
                          ? _compareFaces
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, color: AppTheme.accentSecondary, size: 18),
                    label: const Text('Reset', style: TextStyle(color: AppTheme.accentSecondary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentSecondary),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Text('⚠️ $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 14)),
                ),
              ],

              // Match result
              if (_comparisonResult != null) ...[
                const SizedBox(height: 24),
                _buildMatchMeter(),
                const SizedBox(height: 20),
                _buildComparisonDetails(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlot(int index, File? image, Size? imageSize, List<FaceDetectionResult> results) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Text('Face $index', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImage(index),
          child: image == null
              ? Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor, width: 2),
                    borderRadius: BorderRadius.circular(14),
                    color: AppTheme.accentPrimary.withValues(alpha: 0.03),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📸', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text('Tap to upload', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.file(image, height: 180, width: double.infinity, fit: BoxFit.cover),
                      if (results.isNotEmpty && imageSize != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: FacePainter(results: results, imageSize: imageSize),
                          ),
                        ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: AppTheme.bgPrimary.withValues(alpha: 0.6),
                            child: const Center(
                              child: CircularProgressIndicator(color: AppTheme.accentSecondary, strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMatchMeter() {
    final result = _comparisonResult!;
    final percentage = result.similarityPercentage;
    final color = _getMatchColor(percentage);

    return GlowCard(
      glowColor: color,
      child: Column(
        children: [
          // Animated ring
          AnimatedBuilder(
            animation: _ringAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _MatchRingPainter(
                    percentage: percentage * _ringAnimation.value,
                    color: color,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percentage * _ringAnimation.value).round()}%',
                          style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w800),
                        ),
                        const Text('Match', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_getMatchEmoji(percentage), style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                result.matchLevel,
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Euclidean Distance: ${result.distance.toStringAsFixed(4)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lower distance = more similar faces',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Similarity bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Similarity Score', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: AnimatedBuilder(
                    animation: _ringAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (percentage / 100 * _ringAnimation.value).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Distance & Threshold
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Distance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(result.distance.toStringAsFixed(3),
                          style: const TextStyle(color: AppTheme.accentSecondary, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text('Threshold', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      SizedBox(height: 4),
                      Text('0.6', style: TextStyle(color: AppTheme.accentSecondary, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonDetails() {
    return Column(
      children: [
        if (_results1.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('📋 Image 1 Analysis',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          _buildMiniResultCard(_results1[0]),
        ],
        const SizedBox(height: 16),
        if (_results2.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('📋 Image 2 Analysis',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          _buildMiniResultCard(_results2[0]),
        ],
      ],
    );
  }

  Widget _buildMiniResultCard(FaceDetectionResult result) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildMiniStat('Age', '~${result.estimatedAge ?? "?"}'),
          const SizedBox(width: 12),
          _buildMiniStat('Gender', result.estimatedGender ?? '?'),
          const SizedBox(width: 12),
          _buildMiniStat('Expression', result.dominantExpression ?? 'neutral'),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.accentPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(color: AppTheme.accentSecondary, fontSize: 15, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 70) return AppTheme.success;
    if (percentage >= 50) return AppTheme.warning;
    if (percentage >= 30) return Colors.orange;
    return AppTheme.error;
  }

  String _getMatchEmoji(double percentage) {
    if (percentage >= 70) return '✅';
    if (percentage >= 50) return '🤔';
    if (percentage >= 30) return '⚠️';
    return '❌';
  }

  Future<ImageSource?> _showPickerDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.accentPrimary),
                title: const Text('Gallery', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.accentSecondary),
                title: const Text('Camera', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  _MatchRingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = AppTheme.bgSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_MatchRingPainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.color != color;
}