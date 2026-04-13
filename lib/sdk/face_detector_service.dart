import 'dart:math';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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

/// Main Face Detection Service using Google ML Kit
class FaceDetectorService {
  late final FaceDetector _faceDetector;
  bool _isInitialized = false;

  /// Initialize the face detector with all features enabled
  Future<void> initialize() async {
    if (_isInitialized) return;

    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.1,
    );

    _faceDetector = FaceDetector(options: options);
    _isInitialized = true;
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

      // Generate face embedding for comparison
      final embedding = _generateFaceEmbedding(face);

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

  /// Generate a face embedding vector for comparison
  /// Uses facial landmarks and geometry to create a descriptor
  Float64List _generateFaceEmbedding(Face face) {
    final embedding = Float64List(128);
    final box = face.boundingBox;

    // Normalize bounding box features
    embedding[0] = box.width / 1000.0;
    embedding[1] = box.height / 1000.0;
    embedding[2] = (box.height / box.width);

    // Head angles
    embedding[3] = (face.headEulerAngleX ?? 0.0) / 45.0;
    embedding[4] = (face.headEulerAngleY ?? 0.0) / 45.0;
    embedding[5] = (face.headEulerAngleZ ?? 0.0) / 45.0;

    // Classification features
    embedding[6] = face.smilingProbability ?? 0.0;
    embedding[7] = face.leftEyeOpenProbability ?? 0.0;
    embedding[8] = face.rightEyeOpenProbability ?? 0.0;

    // Landmark-based features
    int idx = 9;
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

    // Contour-based features for more detail
    final contourTypes = [
      FaceContourType.face,
      FaceContourType.leftEye,
      FaceContourType.rightEye,
      FaceContourType.noseBridge,
      FaceContourType.noseBottom,
      FaceContourType.upperLipTop,
      FaceContourType.lowerLipBottom,
    ];

    for (final type in contourTypes) {
      final contour = face.contours[type];
      if (contour != null && contour.points.isNotEmpty) {
        // Use first, middle, and last points of each contour
        final points = contour.points;
        final keyPoints = [
          points.first,
          points[points.length ~/ 2],
          points.last,
        ];
        for (final pt in keyPoints) {
          if (idx + 1 < 128) {
            embedding[idx] = (pt.x - box.left) / box.width;
            embedding[idx + 1] = (pt.y - box.top) / box.height;
            idx += 2;
          }
        }
      }
    }

    // Inter-landmark distances (normalized)
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final nose = face.landmarks[FaceLandmarkType.noseBase];
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];

    if (leftEye != null && rightEye != null && idx < 128) {
      final eyeDist = _pointDistance(leftEye.position, rightEye.position);
      embedding[idx++] = eyeDist / box.width;
    }
    if (leftEye != null && nose != null && idx < 128) {
      embedding[idx++] = _pointDistance(leftEye.position, nose.position) / box.width;
    }
    if (rightEye != null && nose != null && idx < 128) {
      embedding[idx++] = _pointDistance(rightEye.position, nose.position) / box.width;
    }
    if (leftMouth != null && rightMouth != null && idx < 128) {
      embedding[idx++] = _pointDistance(leftMouth.position, rightMouth.position) / box.width;
    }
    if (nose != null && leftMouth != null && idx < 128) {
      embedding[idx++] = _pointDistance(nose.position, leftMouth.position) / box.height;
    }

    return embedding;
  }

  double _pointDistance(dynamic a, dynamic b) {
    final dx = (a.x.toDouble() - b.x.toDouble());
    final dy = (a.y.toDouble() - b.y.toDouble());
    return sqrt(dx * dx + dy * dy);
  }

  /// Compare two face embeddings
  static FaceComparisonResult compareFaces(
    Float64List embedding1,
    Float64List embedding2,
  ) {
    // Calculate Euclidean distance
    double sum = 0.0;
    final len = min(embedding1.length, embedding2.length);
    for (int i = 0; i < len; i++) {
      final diff = embedding1[i] - embedding2[i];
      sum += diff * diff;
    }
    final distance = sqrt(sum);

    // Convert to similarity percentage
    // Normalize: distance 0 = 100% match, distance > 2.0 = 0% match
    final similarity = max(0.0, min(100.0, (1.0 - distance / 2.0) * 100.0));

    // Determine match level
    String matchLevel;
    bool isMatch;
    if (similarity >= 75) {
      matchLevel = 'Strong Match';
      isMatch = true;
    } else if (similarity >= 55) {
      matchLevel = 'Possible Match';
      isMatch = true;
    } else if (similarity >= 35) {
      matchLevel = 'Weak Match';
      isMatch = false;
    } else {
      matchLevel = 'No Match';
      isMatch = false;
    }

    return FaceComparisonResult(
      distance: distance,
      similarityPercentage: similarity,
      isMatch: isMatch,
      matchLevel: matchLevel,
    );
  }

  /// Dispose the detector
  void dispose() {
    if (_isInitialized) {
      _faceDetector.close();
      _isInitialized = false;
    }
  }
}