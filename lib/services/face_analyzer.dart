import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Ölçüm çizgisi (görsel üzerinde gösterilecek), görüntü koordinatlarında.
class MeasureLine {
  final String label;
  final Offset a, b;
  const MeasureLine(this.label, this.a, this.b);
}

class FaceMeasurements {
  final double lengthRatio; // yüz uzunluğu / elmacık genişliği
  final double foreheadRatio; // alın / elmacık
  final double jawRatio; // çene hattı / elmacık
  final double chinTaper; // çene ucu genişliği / çene hattı
  const FaceMeasurements(this.lengthRatio, this.foreheadRatio, this.jawRatio, this.chinTaper);
}

class ShapeScore {
  final String shapeId;
  final double probability; // 0..1
  const ShapeScore(this.shapeId, this.probability);
}

class AnalysisResult {
  final List<Offset> contour;
  final List<MeasureLine> lines;
  final FaceMeasurements measurements;
  final List<ShapeScore> scores; // büyükten küçüğe
  final String? warning;

  const AnalysisResult({required this.contour, required this.lines, required this.measurements, required this.scores, this.warning});

  String get bestShape => scores.first.shapeId;
}

class AnalysisException implements Exception {
  final String message;
  AnalysisException(this.message);
  @override
  String toString() => message;
}

/// Tipik oranlar (ML Kit yüz konturu ölçeğinde). Kalibrasyon gerekirse
/// yalnızca bu tabloyu değiştirmek yeterlidir.
const Map<String, List<double>> _prototypes = {
  //          uzunluk, alın, çene, çene ucu
  'oval': [1.29, 0.90, 0.77, 0.61],
  'round': [1.03, 0.87, 0.80, 0.64],
  'square': [1.08, 0.95, 0.94, 0.77],
  'oblong': [1.53, 0.93, 0.88, 0.70],
  'heart': [1.22, 0.99, 0.68, 0.52],
  'diamond': [1.25, 0.74, 0.69, 0.55],
};
const List<double> _weights = [3.0, 4.0, 4.0, 2.0];
const double _temperature = 0.09;

class FaceShapeAnalyzer {
  /// Fotoğraftaki en büyük yüzü bulur ve yüz şeklini tahmin eder.
  Future<AnalysisResult> analyzeFile(String path) async {
    final detector = FaceDetector(options: FaceDetectorOptions(enableContours: true, performanceMode: FaceDetectorMode.accurate));
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      if (faces.isEmpty) {
        throw AnalysisException('Fotoğrafta yüz bulunamadı. Yüzün tamamen göründüğü, iyi ışıklı bir fotoğraf dene.');
      }
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(a.boundingBox.width * a.boundingBox.height));
      final face = faces.first;
      final contour = face.contours[FaceContourType.face];
      if (contour == null || contour.points.length < 20) {
        throw AnalysisException('Yüz hattı okunamadı. Kameraya düz bakarak tekrar dene.');
      }
      final pts = contour.points.map((p) => Offset(p.x.toDouble(), p.y.toDouble())).toList();
      final yaw = face.headEulerAngleY ?? 0;
      String? warning;
      if (yaw.abs() > 15) {
        warning = 'Başın yana dönük görünüyor; sonuç daha az güvenilir olabilir.';
      }
      return analyzeContour(pts, warning: warning);
    } finally {
      await detector.close();
    }
  }

  /// Saf hesaplama: kontur noktalarından ölçüm ve şekil olasılıkları.
  /// ML Kit yüz konturu 36 noktadır; 0. nokta alnın tepesi, ~18. nokta çene ucudur.
  static AnalysisResult analyzeContour(List<Offset> raw, {String? warning}) {
    final n = raw.length;
    final topP = raw[0];
    final chinP = raw[n ~/ 2];
    // Baş eğikliğini düzelt: alın–çene eksenini dikey yap.
    final angle = math.atan2(chinP.dx - topP.dx, chinP.dy - topP.dy);
    final center = raw.reduce((a, b) => a + b) / n.toDouble();
    Offset rot(Offset p, double a) {
      final d = p - center;
      final c = math.cos(a), s = math.sin(a);
      return Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c) + center;
    }

    final pts = raw.map((p) => rot(p, angle)).toList();
    final top = pts.map((p) => p.dy).reduce(math.min);
    final bottom = pts.map((p) => p.dy).reduce(math.max);
    final height = bottom - top;

    (double, double)? spanAt(double t) {
      final y = top + t * height;
      final xs = <double>[];
      for (var i = 0; i < n; i++) {
        final a = pts[i], b = pts[(i + 1) % n];
        if ((a.dy <= y && b.dy > y) || (b.dy <= y && a.dy > y)) {
          xs.add(a.dx + (y - a.dy) / (b.dy - a.dy) * (b.dx - a.dx));
        }
      }
      if (xs.length < 2) return null;
      return (xs.reduce(math.min), xs.reduce(math.max));
    }

    double widthAt(double t) {
      final s = spanAt(t);
      return s == null ? 0 : s.$2 - s.$1;
    }

    // Elmacık: 0.30–0.58 arasındaki en geniş nokta
    var cheekT = 0.45, cheek = 0.0;
    for (var t = 0.30; t <= 0.58; t += 0.02) {
      final w = widthAt(t);
      if (w > cheek) {
        cheek = w;
        cheekT = t;
      }
    }
    if (cheek <= 0) throw AnalysisException('Ölçüm yapılamadı, lütfen başka bir fotoğraf dene.');

    const foreheadT = 0.12, jawT = 0.78, chinT = 0.92;
    final forehead = widthAt(foreheadT);
    final jaw = widthAt(jawT);
    final chinW = widthAt(chinT);

    final m = FaceMeasurements(height / cheek, forehead / cheek, jaw / cheek, jaw == 0 ? 0 : chinW / jaw);

    // Prototiplere ağırlıklı uzaklık → softmax
    final v = [m.lengthRatio, m.foreheadRatio, m.jawRatio, m.chinTaper];
    final raw2 = <String, double>{};
    _prototypes.forEach((id, p) {
      var d = 0.0;
      for (var i = 0; i < 4; i++) {
        d += _weights[i] * math.pow(v[i] - p[i], 2);
      }
      raw2[id] = math.exp(-math.sqrt(d) / _temperature);
    });
    final sum = raw2.values.fold<double>(0, (a, b) => a + b);
    final scores = raw2.entries.map((e) => ShapeScore(e.key, sum == 0 ? 1 / 6 : e.value / sum)).toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));

    // Ölçüm çizgilerini orijinal görüntü açısına geri döndür
    MeasureLine? line(String label, double t) {
      final s = spanAt(t);
      if (s == null) return null;
      final y = top + t * height;
      return MeasureLine(label, rot(Offset(s.$1, y), -angle), rot(Offset(s.$2, y), -angle));
    }

    final cx = (pts.map((p) => p.dx).reduce(math.min) + pts.map((p) => p.dx).reduce(math.max)) / 2;
    final lines = <MeasureLine>[
      ?line('Alın', foreheadT),
      ?line('Elmacık', cheekT),
      ?line('Çene', jawT),
      MeasureLine('Uzunluk', rot(Offset(cx, top), -angle), rot(Offset(cx, bottom), -angle)),
    ];

    return AnalysisResult(contour: raw, lines: lines, measurements: m, scores: scores, warning: warning);
  }
}
