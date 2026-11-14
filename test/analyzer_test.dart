import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:facefit/services/face_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uygulamadaki çizim oranlarından, ML Kit konturuna benzeyen (alnın üstü
/// kesilmiş) sentetik bir yüz konturu üretir.
List<Offset> syntheticContour(Map<String, dynamic> o) {
  double v(String k) => (o[k] as num).toDouble();
  final r = [
    const Offset(0, 0),
    Offset(v('forehead') * .7, .04),
    Offset(v('forehead'), .2),
    Offset(v('cheek'), .45),
    Offset((v('cheek') + v('jaw')) / 2, .61),
    Offset(v('jaw'), .77),
    Offset(v('chin'), .97),
    const Offset(0, 1),
  ];
  final len = 2 * 46 * v('height') * .92;
  final p = [
    for (final q in r) Offset(q.dx * 46, q.dy * len),
    for (final q in r.reversed.skip(1).take(r.length - 2)) Offset(-q.dx * 46, q.dy * len),
  ];
  final n = p.length, out = <Offset>[];
  for (var i = 0; i < n; i++) {
    final p0 = p[(i - 1 + n) % n], p1 = p[i], p2 = p[(i + 1) % n], p3 = p[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
    for (var k = 0; k < 10; k++) {
      final u = k / 10;
      final a = math.pow(1 - u, 3).toDouble(), b = 3 * math.pow(1 - u, 2).toDouble() * u, c = 3 * (1 - u) * u * u, d = u * u * u;
      out.add(p1 * a + c1 * b + c2 * c + p2 * d);
    }
  }
  final cut = 0.1 * len;
  return out.map((q) => Offset(q.dx + 300, math.max(q.dy, cut) + 200)).toList();
}

void main() {
  final data = jsonDecode(File('assets/data/face_shapes.json').readAsStringSync()) as Map<String, dynamic>;

  for (final s in data['shapes'] as List<dynamic>) {
    test('${s['id']} çizimi kendi şekli olarak tanınır', () {
      final r = FaceShapeAnalyzer.analyzeContour(syntheticContour(s['outline'] as Map<String, dynamic>));
      expect(r.bestShape, s['id']);
    });
  }

  test('olasılıklar toplamı 1', () {
    final s = (data['shapes'] as List<dynamic>).first;
    final r = FaceShapeAnalyzer.analyzeContour(syntheticContour(s['outline'] as Map<String, dynamic>));
    expect(r.scores.fold<double>(0, (a, x) => a + x.probability), closeTo(1, 1e-9));
  });
}
