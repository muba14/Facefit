// Uygulamanın veri modelleri. Tüm içerik `assets/data/face_shapes.json`
// dosyasından okunur; böylece öneriler kod değiştirmeden güncellenebilir.

class HairSpec {
  final double top; // tepe hacmi (px, 200x240 çizim alanında)
  final double side; // yan kalınlık
  final double sideDown; // yanların ineceği nokta (yüz uzunluğuna oran)
  final double fringe; // kakülün alnı kapatma oranı (0..1)
  final double peakShift; // tepe noktasının sağa kayması (quiff)
  final double peakWidth; // tepe genişliği (faux hawk için dar)
  final bool texture, slick, part, undercut, bun;

  const HairSpec({
    required this.top,
    required this.side,
    required this.sideDown,
    this.fringe = 0,
    this.peakShift = 0,
    this.peakWidth = 1,
    this.texture = false,
    this.slick = false,
    this.part = false,
    this.undercut = false,
    this.bun = false,
  });

  factory HairSpec.fromJson(Map<String, dynamic> j) => HairSpec(
    top: (j['top'] as num).toDouble(),
    side: (j['side'] as num).toDouble(),
    sideDown: (j['sideDown'] as num).toDouble(),
    fringe: (j['fringe'] as num?)?.toDouble() ?? 0,
    peakShift: (j['peakShift'] as num?)?.toDouble() ?? 0,
    peakWidth: (j['peakWidth'] as num?)?.toDouble() ?? 1,
    texture: j['texture'] == true,
    slick: j['slick'] == true,
    part: j['part'] == true,
    undercut: j['undercut'] == true,
    bun: j['bun'] == true,
  );

  /// Sakal önizlemelerinde kullanılan sade, kısa saç.
  static const neutral = HairSpec(top: 8, side: 3, sideDown: 0.42, texture: true);
}

class HairStyle {
  final String id, name, length, care;
  final HairSpec spec;
  const HairStyle(this.id, this.name, this.length, this.care, this.spec);
}

enum BeardType { none, full, goatee, circle, anchor, strap }

class BeardSpec {
  final BeardType type;
  final double length;
  final bool stubble;
  final double cheekLine;

  const BeardSpec({required this.type, this.length = 0, this.stubble = false, this.cheekLine = 0.55});

  factory BeardSpec.fromJson(Map<String, dynamic> j) => BeardSpec(
    type: BeardType.values.byName(j['type'] as String),
    length: (j['length'] as num?)?.toDouble() ?? 0,
    stubble: j['stubble'] == true,
    cheekLine: (j['cheekLine'] as num?)?.toDouble() ?? 0.55,
  );

  static const none = BeardSpec(type: BeardType.none);
}

class BeardStyle {
  final String id, name;
  final BeardSpec spec;
  const BeardStyle(this.id, this.name, this.spec);
}

/// Yüz çizimi için oranlar (yarı genişlikler, yüz genişliği birimine göre).
class FaceOutline {
  final double height, forehead, cheek, jaw, chin;
  const FaceOutline(this.height, this.forehead, this.cheek, this.jaw, this.chin);

  factory FaceOutline.fromJson(Map<String, dynamic> j) => FaceOutline(
    (j['height'] as num).toDouble(),
    (j['forehead'] as num).toDouble(),
    (j['cheek'] as num).toDouble(),
    (j['jaw'] as num).toDouble(),
    (j['chin'] as num).toDouble(),
  );
}

class Recommendation {
  final String id; // saç veya sakal stili id'si
  final String why;
  const Recommendation(this.id, this.why);
}

class Outfit {
  final String name;
  final List<String> items;
  final List<int> palette; // ARGB renkler
  const Outfit(this.name, this.items, this.palette);
}

class StyleGuide {
  final List<String> collars, glasses, hats, avoid;
  const StyleGuide(this.collars, this.glasses, this.hats, this.avoid);
}

class FaceShape {
  final String id, name, summary, goal, hairAvoid, beardAvoid;
  final FaceOutline outline;
  final List<String> traits;
  final List<Recommendation> hair, beard;
  final StyleGuide style;
  final List<Outfit> outfits;

  const FaceShape({
    required this.id,
    required this.name,
    required this.summary,
    required this.goal,
    required this.hairAvoid,
    required this.beardAvoid,
    required this.outline,
    required this.traits,
    required this.hair,
    required this.beard,
    required this.style,
    required this.outfits,
  });
}
