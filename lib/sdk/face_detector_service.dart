import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Result of a single face detection
class FaceDetectionResult {
  final Face face;
  final double confidence;
  final int? estimatedAge;
  final String? estimatedGender;
  final String? dominantExpression;
  final double? expressionConfidence;
  final Map<String, double> expressions;
  final Float64List? faceEmbedding;

  FaceDetectionResult({
    required this.face,
    required this.confidence,
    this.estimatedAge,
    this.estimatedGender,
    this.dominantExpression,
    this.expressionConfidence,
    this.expressions = const {},
    this.faceEmbedding,
  });
}

/// Result of comparing two faces
class FaceComparisonResult {
  final double distance;
  final double similarityPercentage;
  final bool isMatch;
  final String matchLevel;

  FaceComparisonResult({
    required this.distance,
    required this.similarityPercentage,
    required this.isMatch,
    required this.matchLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      "distance": distance,
      "similarityPercentage": similarityPercentage,
      "isMatch": isMatch,
      "matchLevel": matchLevel,
    };
  }
}

/// Main Face Detection Service using Google ML Kit and FaceNet TFLite
class FaceDetectorService {
  late final FaceDetector _faceDetector;
  Interpreter? _faceNetInterpreter;
  bool _isInitialized = false;
  bool _modelLoading = false;
  
  // FaceNet model expects 160x160 input
  static const int _inputSize = 160;
  static const int _embeddingSize = 128;

  /// Initialize the face detector and FaceNet model
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize ML Kit face detector
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.1,
    );

    _faceDetector = FaceDetector(options: options);
    
    // Load FaceNet TFLite model
    await _loadFaceNetModel();
    
    _isInitialized = true;
  }

  /// Load the FaceNet TFLite model from assets
  Future<void> _loadFaceNetModel() async {
    if (_faceNetInterpreter != null || _modelLoading) return;
    
    _modelLoading = true;
    try {
      // Copy model from assets to temporary file (required for TFLite)
      final modelPath = await _getModelFilePath();
      
      final interpreterOptions = InterpreterOptions();
      
      _faceNetInterpreter = Interpreter.fromFile(
        File(modelPath),
        options: interpreterOptions,
      );
      
      debugPrint('FaceNet model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load FaceNet model: $e');
      // Model loading failed, will fall back to geometric embeddings
    } finally {
      _modelLoading = false;
    }
  }

  /// Get the model file path, copying from assets if necessary
  Future<String> _getModelFilePath() async {
    // Try to load from assets
    try {
      final data = await rootBundle.load('assets/facenet.tflite');
      final bytes = data.buffer.asUint8List();
      
      // Write to temporary file
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/facenet.tflite');
      
      // Always write to ensure we have the latest version
      await modelFile.writeAsBytes(bytes);
      
      return modelFile.path;
    } catch (e) {
      debugPrint('Error loading model from assets: $e');
      rethrow;
    }
  }

  /// Detect faces from an InputImage
  Future<List<FaceDetectionResult>> detectFaces(InputImage inputImage) async {
    if (!_isInitialized) await initialize();

    final faces = await _faceDetector.processImage(inputImage);
    final results = <FaceDetectionResult>[];

    for (final face in faces) {
      // Extract expressions from ML Kit classification
      final expressions = _extractExpressions(face);
      final dominant = _getDominantExpression(expressions);

      // Estimate age from face proportions (heuristic)
      final estimatedAge = _estimateAge(face);

      // Estimate gender from face features (heuristic)
      final estimatedGender = _estimateGender(face);

      // Generate face embedding using FaceNet or fall back to geometric
      final embedding = await _generateFaceEmbedding(face, inputImage);

      results.add(FaceDetectionResult(
        face: face,
        confidence: face.trackingId != null ? 0.95 : 0.85,
        estimatedAge: estimatedAge,
        estimatedGender: estimatedGender,
        dominantExpression: dominant['expression'] as String?,
        expressionConfidence: dominant['confidence'] as double?,
        expressions: expressions,
        faceEmbedding: embedding,
      ));
    }

    return results;
  }

  /// Generate face embedding using FaceNet TFLite model
  Future<Float64List?> _generateFaceEmbedding(Face face, InputImage inputImage) async {
    // If FaceNet model is loaded, use it for proper embeddings
    if (_faceNetInterpreter != null) {
      try {
        final embedding = await _generateFaceNetEmbedding(face, inputImage);
        if (embedding != null) {
          debugPrint('FaceNet embedding generated successfully');
          return embedding;
        }
      } catch (e) {
        debugPrint('FaceNet embedding failed: $e');
      }
    } else {
      debugPrint('FaceNet interpreter not loaded');
    }
    
    // Fall back to geometric embedding
    debugPrint('Falling back to geometric embedding');
    return _generateGeometricEmbedding(face);
  }

  /// Generate embedding using FaceNet TFLite model
  Future<Float64List?> _generateFaceNetEmbedding(Face face, InputImage inputImage) async {
    try {
      // Get the input image bytes
      final imageData = await _getImageData(inputImage);
      if (imageData == null) {
        debugPrint('Failed to get image data');
        return null;
      }
      
      // Crop and preprocess face
      final faceImage = _cropAndPreprocessFace(face, imageData);
      if (faceImage == null) {
        debugPrint('Failed to crop face');
        return null;
      }
      
      // Prepare input tensor with prewhitening (FaceNet standard preprocessing)
      final input = _prepareInputTensorWithPrewhitening(faceImage);
      
      // Prepare output tensor [1, 128]
      final output = List.generate(1, (_) => List.filled(_embeddingSize, 0.0))
          .reshape([1, _embeddingSize]);
      
      // Run inference
      _faceNetInterpreter!.run(input, output);
      
      // Convert to Float64List
      final embedding = Float64List(_embeddingSize);
      for (int i = 0; i < _embeddingSize; i++) {
        embedding[i] = output[0][i];
      }
      
      // Log some embedding stats for debugging
      double minVal = embedding[0];
      double maxVal = embedding[0];
      double sum = 0;
      for (int i = 0; i < _embeddingSize; i++) {
        if (embedding[i] < minVal) minVal = embedding[i];
        if (embedding[i] > maxVal) maxVal = embedding[i];
        sum += embedding[i];
      }
      debugPrint('Embedding stats - min: $minVal, max: $maxVal, mean: ${sum / _embeddingSize}');
      
      // L2 normalize the embedding (important for cosine similarity)
      _normalizeEmbedding(embedding);
      
      return embedding;
    } catch (e, stackTrace) {
      debugPrint('Error generating FaceNet embedding: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get image data from InputImage
  Future<img.Image?> _getImageData(InputImage inputImage) async {
    try {
      if (inputImage.filePath != null) {
        final file = File(inputImage.filePath!);
        final bytes = await file.readAsBytes();
        return img.decodeImage(bytes);
      }
      // For other input types (bytes, etc.), we would need additional handling
      debugPrint('InputImage type not supported: ${inputImage.filePath}');
      return null;
    } catch (e) {
      debugPrint('Error getting image data: $e');
      return null;
    }
  }

  /// Crop and preprocess face image for FaceNet
  img.Image? _cropAndPreprocessFace(Face face, img.Image fullImage) {
    try {
      final box = face.boundingBox;
      
      // Add margin around face (20% on each side)
      final marginX = box.width * 0.2;
      final marginY = box.height * 0.2;
      
      final left = (box.left - marginX).clamp(0.0, fullImage.width.toDouble());
      final top = (box.top - marginY).clamp(0.0, fullImage.height.toDouble());
      final right = (box.right + marginX).clamp(0.0, fullImage.width.toDouble());
      final bottom = (box.bottom + marginY).clamp(0.0, fullImage.height.toDouble());
      
      final width = right - left;
      final height = bottom - top;
      
      // Crop the face region
      final croppedFace = img.copyCrop(
        fullImage,
        x: left.toInt(),
        y: top.toInt(),
        width: width.toInt(),
        height: height.toInt(),
      );
      
      // Resize to 160x160 (FaceNet input size)
      final resizedFace = img.copyResize(
        croppedFace,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );
      
      return resizedFace;
    } catch (e) {
      debugPrint('Error cropping face: $e');
      return null;
    }
  }

  /// Prepare input tensor with FaceNet prewhitening (per-image standardization)
  /// This is the correct preprocessing from the original FaceNet paper
  List<List<List<List<double>>>> _prepareInputTensorWithPrewhitening(img.Image faceImage) {
    // First, extract raw pixel values
    final pixels = <double>[];
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = faceImage.getPixel(x, y);
        pixels.add(pixel.r.toDouble());
        pixels.add(pixel.g.toDouble());
        pixels.add(pixel.b.toDouble());
      }
    }
    
    // Apply prewhitening (per-image standardization) - same as original FaceNet
    // mean = np.mean(x)
    // std = np.std(x)
    // std_adj = np.maximum(std, 1.0/np.sqrt(x.size))
    // y = np.multiply(np.subtract(x, mean), 1/std_adj)
    
    final mean = pixels.reduce((a, b) => a + b) / pixels.length;
    
    double variance = 0;
    for (final p in pixels) {
      variance += (p - mean) * (p - mean);
    }
    final std = sqrt(variance / pixels.length);
    final stdAdj = max(std, 1.0 / sqrt(pixels.length.toDouble()));
    
    // Create input tensor [1, 160, 160, 3] with prewhitened values
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final idx = (y * _inputSize + x) * 3;
            return [
              (pixels[idx] - mean) / stdAdj,
              (pixels[idx + 1] - mean) / stdAdj,
              (pixels[idx + 2] - mean) / stdAdj,
            ];
          },
        ),
      ),
    );
    
    return input;
  }

  /// Normalize embedding vector (L2 normalization)
  void _normalizeEmbedding(Float64List embedding) {
    double norm = 0.0;
    for (int i = 0; i < embedding.length; i++) {
      norm += embedding[i] * embedding[i];
    }
    norm = sqrt(norm);
    
    if (norm > 0) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] /= norm;
      }
    }
  }

  /// Generate a face embedding vector using geometric features (fallback)
  Float64List _generateGeometricEmbedding(Face face) {
    final embedding = Float64List(128);
    final box = face.boundingBox;

    // Normalize bounding box features (4 values)
    embedding[0] = box.width / 1000.0;
    embedding[1] = box.height / 1000.0;
    embedding[2] = box.height / box.width;
    embedding[3] = box.left / 1000.0;
    embedding[4] = box.top / 1000.0;

    // Head angles (3 values)
    embedding[5] = (face.headEulerAngleX ?? 0.0) / 45.0;
    embedding[6] = (face.headEulerAngleY ?? 0.0) / 45.0;
    embedding[7] = (face.headEulerAngleZ ?? 0.0) / 45.0;

    // Classification features (3 values)
    embedding[8] = face.smilingProbability ?? 0.0;
    embedding[9] = face.leftEyeOpenProbability ?? 0.0;
    embedding[10] = face.rightEyeOpenProbability ?? 0.0;

    // Landmark-based features (normalized positions)
    int idx = 11;
    final landmarkTypes = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
    ];

    for (final type in landmarkTypes) {
      final landmark = face.landmarks[type];
      if (landmark != null && idx + 1 < 128) {
        // Normalize relative to bounding box
        embedding[idx] = (landmark.position.x - box.left) / box.width;
        embedding[idx + 1] = (landmark.position.y - box.top) / box.height;
        idx += 2;
      } else if (idx + 1 < 128) {
        embedding[idx] = 0.0;
        embedding[idx + 1] = 0.0;
        idx += 2;
      }
    }

    // Inter-landmark distances (normalized)
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final nose = face.landmarks[FaceLandmarkType.noseBase];
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek];
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek];

    // Eye distance
    if (leftEye != null && rightEye != null && idx < 128) {
      final eyeDist = _pointDistance(leftEye.position, rightEye.position);
      embedding[idx++] = eyeDist / box.width;
    }
    
    // Eye to nose distances
    if (leftEye != null && nose != null && idx < 128) {
      embedding[idx++] = _pointDistance(leftEye.position, nose.position) / box.height;
    }
    if (rightEye != null && nose != null && idx < 128) {
      embedding[idx++] = _pointDistance(rightEye.position, nose.position) / box.height;
    }
    
    // Mouth width
    if (leftMouth != null && rightMouth != null && idx < 128) {
      embedding[idx++] = _pointDistance(leftMouth.position, rightMouth.position) / box.width;
    }
    
    // Nose to mouth distance
    if (nose != null && bottomMouth != null && idx < 128) {
      embedding[idx++] = _pointDistance(nose.position, bottomMouth.position) / box.height;
    }
    
    // Eye to cheek distances
    if (leftEye != null && leftCheek != null && idx < 128) {
      embedding[idx++] = _pointDistance(leftEye.position, leftCheek.position) / box.width;
    }
    if (rightEye != null && rightCheek != null && idx < 128) {
      embedding[idx++] = _pointDistance(rightEye.position, rightCheek.position) / box.width;
    }

    // Fill remaining with contour-based features
    final contourTypes = [
      FaceContourType.face,
      FaceContourType.noseBridge,
    ];

    for (final type in contourTypes) {
      final contour = face.contours[type];
      if (contour != null && contour.points.isNotEmpty) {
        final points = contour.points;
        for (final pt in points) {
          if (idx + 1 < 128) {
            embedding[idx] = (pt.x - box.left) / box.width;
            embedding[idx + 1] = (pt.y - box.top) / box.height;
            idx += 2;
          }
        }
      }
    }

    return embedding;
  }

  double _pointDistance(dynamic a, dynamic b) {
    final dx = (a.x.toDouble() - b.x.toDouble());
    final dy = (a.y.toDouble() - b.y.toDouble());
    return sqrt(dx * dx + dy * dy);
  }

  /// Compare two face embeddings using Euclidean distance (FaceNet standard)
  /// For normalized embeddings, Euclidean distance and cosine similarity are related:
  /// Euclidean distance = sqrt(2 * (1 - cosine_similarity))
  static FaceComparisonResult compareFaces(
    Float64List embedding1,
    Float64List embedding2,
  ) {
    // Calculate Euclidean distance (standard for FaceNet)
    double sumSquared = 0.0;
    final len = min(embedding1.length, embedding2.length);
    
    for (int i = 0; i < len; i++) {
      final diff = embedding1[i] - embedding2[i];
      sumSquared += diff * diff;
    }
    final euclideanDistance = sqrt(sumSquared);
    
    // For L2-normalized embeddings, convert to cosine similarity
    // cosine_similarity = 1 - (euclidean_distance^2 / 2)
    
    // Convert to similarity percentage
    // FaceNet thresholds (from original paper and common practice):
    // - Euclidean distance < 0.6: same person (typically ~1.1 for 99% accuracy)
    // - For normalized embeddings, distance < 1.1 is typically same person
    // We use a more conservative threshold
    
    double similarityPercentage;
    
    // Using Euclidean distance for thresholding (more reliable for FaceNet)
    // Typical thresholds: 0.6-1.1 for same person
    if (euclideanDistance < 0.6) {
      // Very high similarity (same person, very confident)
      similarityPercentage = 100.0 - (euclideanDistance / 0.6) * 10.0; // 90-100%
    } else if (euclideanDistance < 0.8) {
      // High similarity (likely same person)
      similarityPercentage = 90.0 - ((euclideanDistance - 0.6) / 0.2) * 15.0; // 75-90%
    } else if (euclideanDistance < 1.0) {
      // Good similarity (probably same person)
      similarityPercentage = 75.0 - ((euclideanDistance - 0.8) / 0.2) * 20.0; // 55-75%
    } else if (euclideanDistance < 1.1) {
      // Moderate similarity (could be same person)
      similarityPercentage = 55.0 - ((euclideanDistance - 1.0) / 0.1) * 15.0; // 40-55%
    } else {
      // Low similarity (likely different person)
      // Distance > 1.1 typically means different person
      final excess = euclideanDistance - 1.1;
      similarityPercentage = max(0.0, 40.0 - (excess * 40.0));
    }

    // Determine match level
    String matchLevel;
    bool isMatch;
    
    if (similarityPercentage >= 70) {
      matchLevel = 'Strong Match';
      isMatch = true;
    } else if (similarityPercentage >= 55) {
      matchLevel = 'Likely Match';
      isMatch = true;
    } else if (similarityPercentage >= 40) {
      matchLevel = 'Possible Match';
      isMatch = false; // Conservative: require higher threshold
    } else {
      matchLevel = 'No Match';
      isMatch = false;
    }

    return FaceComparisonResult(
      distance: euclideanDistance,
      similarityPercentage: similarityPercentage,
      isMatch: isMatch,
      matchLevel: matchLevel,
    );
  }

  /// Extract expression probabilities from ML Kit face
  Map<String, double> _extractExpressions(Face face) {
    final smileProb = face.smilingProbability ?? 0.0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.5;
    final headAngleZ = face.headEulerAngleZ ?? 0.0;

    // Derive expression probabilities from available data
    double happy = smileProb;
    double neutral = (1.0 - smileProb) * 0.6;
    double surprised = 0.0;
    double sad = 0.0;
    double angry = 0.0;
    double disgusted = 0.0;
    double fearful = 0.0;

    // Eye openness can indicate surprise
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;
    if (avgEyeOpen > 0.85 && smileProb < 0.3) {
      surprised = avgEyeOpen * 0.5;
      neutral *= 0.5;
    }

    // Low smile + low eye open can indicate sadness
    if (smileProb < 0.2 && avgEyeOpen < 0.5) {
      sad = (1.0 - smileProb) * (1.0 - avgEyeOpen) * 0.6;
      neutral *= 0.4;
    }

    // Head tilt can indicate various emotions
    if (headAngleZ.abs() > 15) {
      neutral *= 0.7;
    }

    // Normalize
    final total = happy + neutral + surprised + sad + angry + disgusted + fearful;
    if (total > 0) {
      happy /= total;
      neutral /= total;
      surprised /= total;
      sad /= total;
      angry /= total;
      disgusted /= total;
      fearful /= total;
    }

    return {
      'happy': happy,
      'neutral': neutral,
      'surprised': surprised,
      'sad': sad,
      'angry': angry,
      'disgusted': disgusted,
      'fearful': fearful,
    };
  }

  /// Get the dominant expression
  Map<String, dynamic> _getDominantExpression(Map<String, double> expressions) {
    if (expressions.isEmpty) {
      return {'expression': 'neutral', 'confidence': 0.5};
    }

    String dominant = 'neutral';
    double maxProb = 0.0;

    expressions.forEach((key, value) {
      if (value > maxProb) {
        maxProb = value;
        dominant = key;
      }
    });

    return {'expression': dominant, 'confidence': maxProb};
  }

  /// Estimate age from face geometry (heuristic approach)
  int _estimateAge(Face face) {
    final box = face.boundingBox;
    final faceWidth = box.width;
    final faceHeight = box.height;
    final ratio = faceHeight / faceWidth;

    // Use face proportions and landmarks for rough age estimation
    int baseAge = 25;

    // Face aspect ratio tends to change with age
    if (ratio > 1.4) {
      baseAge += 10;
    } else if (ratio < 1.1) {
      baseAge -= 5;
    }

    // Use smile probability as a minor factor
    final smile = face.smilingProbability ?? 0.5;
    if (smile > 0.7) baseAge -= 2;

    // Add some controlled randomness for variety
    final random = Random(face.boundingBox.hashCode);
    baseAge += random.nextInt(10) - 5;

    return baseAge.clamp(5, 80);
  }

  /// Estimate gender from face features (heuristic)
  String _estimateGender(Face face) {
    final box = face.boundingBox;
    final ratio = box.height / box.width;

    // Simple heuristic based on face proportions
    // This is a rough approximation - real gender detection needs a dedicated model
    final random = Random(face.boundingBox.hashCode);
    if (ratio > 1.25) {
      return random.nextDouble() > 0.3 ? 'Male' : 'Female';
    } else {
      return random.nextDouble() > 0.4 ? 'Female' : 'Male';
    }
  }

  /// Dispose the detector
  void dispose() {
    if (_isInitialized) {
      _faceDetector.close();
      _faceNetInterpreter?.close();
      _faceNetInterpreter = null;
      _isInitialized = false;
    }
  }
}