import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// JSON içeriğini bir kez yükleyip bellekte tutar.
class StyleRepository {
  StyleRepository._();
  static final StyleRepository instance = StyleRepository._();

  final Map<String, HairStyle> hairStyles = {};
  final Map<String, BeardStyle> beardStyles = {};
  final List<FaceShape> shapes = [];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/face_shapes.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    (data['hairStyles'] as Map<String, dynamic>).forEach((id, v) {
      final m = v as Map<String, dynamic>;
      hairStyles[id] = HairStyle(
        id,
        m['name'] as String,
        m['length'] as String,
        m['care'] as String,
        HairSpec.fromJson(m['spec'] as Map<String, dynamic>),
      );
    });

    (data['beardStyles'] as Map<String, dynamic>).forEach((id, v) {
      final m = v as Map<String, dynamic>;
      beardStyles[id] = BeardStyle(id, m['name'] as String, BeardSpec.fromJson(m['spec'] as Map<String, dynamic>));
    });

    for (final s in data['shapes'] as List<dynamic>) {
      final m = s as Map<String, dynamic>;
      final style = m['style'] as Map<String, dynamic>;
      List<String> strings(dynamic l) => (l as List<dynamic>).cast<String>();
      List<Recommendation> recs(dynamic l) =>
          (l as List<dynamic>).map((e) => Recommendation(e['id'] as String, e['why'] as String)).toList();

      shapes.add(
        FaceShape(
          id: m['id'] as String,
          name: m['name'] as String,
          summary: m['summary'] as String,
          goal: m['goal'] as String,
          hairAvoid: m['hairAvoid'] as String,
          beardAvoid: m['beardAvoid'] as String,
          outline: FaceOutline.fromJson(m['outline'] as Map<String, dynamic>),
          traits: strings(m['traits']),
          hair: recs(m['hair']),
          beard: recs(m['beard']),
          style: StyleGuide(strings(style['collars']), strings(style['glasses']), strings(style['hats']), strings(style['avoid'])),
          outfits: (m['outfits'] as List<dynamic>).map((o) {
            return Outfit(
              o['name'] as String,
              strings(o['items']),
              (o['palette'] as List<dynamic>).map((h) => int.parse('FF${(h as String).substring(1)}', radix: 16)).toList(),
            );
          }).toList(),
        ),
      );
    }
    _loaded = true;
  }

  FaceShape shape(String id) => shapes.firstWhere((s) => s.id == id);
}
