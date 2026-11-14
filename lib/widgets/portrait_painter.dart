import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';

/// Yüz geometrisi: tüm çizimler 200x240'lık sanal bir alanda yapılır,
/// sonra widget boyutuna ölçeklenir.
class FaceGeometry {
  static const double w = 200, h = 240, cx = 100, unit = 46;

  final FaceOutline o;
  late final double length = 2 * unit * o.height * 0.92;
  late final double top = 128 - length / 2 + 6;

  /// Sağ yarı kontrol noktaları: (yarı genişlik oranı, dikey oran t)
  late final List<Offset> _right = [
    const Offset(0, 0),
    Offset(o.forehead * 0.70, 0.04),
    Offset(o.forehead, 0.20),
    Offset(o.cheek, 0.45),
    Offset((o.cheek + o.jaw) / 2, 0.61),
    Offset(o.jaw, 0.77),
    Offset(o.chin, 0.97),
    const Offset(0, 1),
  ];

  FaceGeometry(this.o);

  double y(double t) => top + t * length;

  /// Verilen t yüksekliğinde yüzün yarı genişliği (px).
  double halfAt(double t) {
    for (var i = 0; i < _right.length - 1; i++) {
      final a = _right[i], b = _right[i + 1];
      if (t >= a.dy && t <= b.dy) {
        final k = (b.dy - a.dy) == 0 ? 0.0 : (t - a.dy) / (b.dy - a.dy);
        return (a.dx + (b.dx - a.dx) * k) * unit;
      }
    }
    return 0;
  }

  Path facePath() {
    final pts = <Offset>[
      for (final p in _right) Offset(cx + p.dx * unit, y(p.dy)),
      for (final p in _right.reversed.skip(1).take(_right.length - 2)) Offset(cx - p.dx * unit, y(p.dy)),
    ];
    return catmullRom(pts, closed: true);
  }

  static Path catmullRom(List<Offset> p, {bool closed = false, Path? into}) {
    final path = (into ?? Path())..moveTo(p[0].dx, p[0].dy);
    final n = p.length;
    final segs = closed ? n : n - 1;
    Offset at(int i) => closed ? p[(i + n) % n] : p[i.clamp(0, n - 1)];
    for (var i = 0; i < segs; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (closed) path.close();
    return path;
  }
}

/// Yüz şekli + saç + sakal içeren minimal çizgi portre.
class PortraitPainter extends CustomPainter {
  final FaceOutline outline;
  final HairSpec hair;
  final BeardSpec beard;

  PortraitPainter({required this.outline, this.hair = HairSpec.neutral, this.beard = BeardSpec.none});

  static const skin = Color(0xFFF3E2CF);
  static const hairColor = Color(0xFF3A2D27);

  @override
  void paint(Canvas canvas, Size size) {
    // Görünen alan: başın üstü ile omuzlar arası (boş kenarlar kırpılır)
    const vx = 10.0, vy = 14.0, vw = 180.0, vh = 200.0;
    final s = math.min(size.width / vw, size.height / vh);
    canvas.save();
    canvas.translate((size.width - vw * s) / 2, (size.height - vh * s) / 2);
    canvas.scale(s);
    canvas.translate(-vx, -vy);

    final g = FaceGeometry(outline);
    final ink = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final skinFill = Paint()..color = skin;
    final hairFill = Paint()..color = hairColor;
    const cx = FaceGeometry.cx;
    const u = FaceGeometry.unit;

    // Boyun + omuz çizgisi
    final neckHalf = outline.jaw * u * 0.55;
    final neck = Path()
      ..moveTo(cx - neckHalf, g.y(0.8))
      ..lineTo(cx - neckHalf, 226)
      ..quadraticBezierTo(cx - neckHalf - 30, 230, cx - 80, 240)
      ..lineTo(cx + 80, 240)
      ..quadraticBezierTo(cx + neckHalf + 30, 230, cx + neckHalf, 226)
      ..lineTo(cx + neckHalf, g.y(0.8))
      ..close();
    canvas.drawPath(neck, skinFill);
    canvas.drawPath(neck, ink);
    // Tişört yakası
    final shirt = Path()
      ..moveTo(cx - 80, 240)
      ..quadraticBezierTo(cx - neckHalf - 26, 231, cx - neckHalf - 2, 228)
      ..quadraticBezierTo(cx, 242, cx + neckHalf + 2, 228)
      ..quadraticBezierTo(cx + neckHalf + 26, 231, cx + 80, 240)
      ..close();
    canvas.drawPath(shirt, Paint()..color = AppColors.accentSoft);

    // Kulaklar
    for (final dir in [-1.0, 1.0]) {
      final ex = cx + dir * (g.halfAt(0.47) + 1);
      final ear = Rect.fromCenter(center: Offset(ex, g.y(0.48)), width: 11, height: g.length * 0.17);
      canvas.drawOval(ear, skinFill);
      canvas.drawOval(ear, ink);
    }

    // Uzun saçın arka kısmı (yüzün arkasında kalır)
    final face = g.facePath();
    if (hair.sideDown > 0.7) {
      _drawHair(canvas, g, hairFill, backLayer: true);
    }

    canvas.drawPath(face, skinFill);
    canvas.drawPath(face, ink);

    // Sakal (yüzün üstünde, saçın altında)
    _drawBeard(canvas, g);

    // Yüz detayları
    _drawFeatures(canvas, g, ink);

    // Saç
    _drawHair(canvas, g, hairFill, backLayer: false);

    canvas.restore();
  }

  void _drawFeatures(Canvas canvas, FaceGeometry g, Paint ink) {
    const cx = FaceGeometry.cx;
    final eyeDx = g.halfAt(0.42) * 0.42;
    final eyeY = g.y(0.43);
    final brow = Paint()
      ..color = hairColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final d in [-1.0, 1.0]) {
      final ex = cx + d * eyeDx;
      canvas.drawOval(Rect.fromCenter(center: Offset(ex, eyeY), width: 9, height: 5.5), Paint()..color = Colors.white);
      canvas.drawCircle(Offset(ex, eyeY), 2.2, Paint()..color = AppColors.ink);
      final b = Path()
        ..moveTo(ex - 8 * d, eyeY - 7)
        ..quadraticBezierTo(ex - 1 * d, eyeY - 11, ex + 8 * d, eyeY - 8);
      canvas.drawPath(b, brow);
    }
    // Burun
    final nose = Path()
      ..moveTo(cx - 1, g.y(0.47))
      ..quadraticBezierTo(cx - 6, g.y(0.58), cx - 1, g.y(0.61))
      ..lineTo(cx + 4, g.y(0.6));
    canvas.drawPath(nose, ink..strokeWidth = 1.3);
    // Ağız
    final my = g.y(0.72);
    final mw = g.halfAt(0.72) * 0.32;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, my + 1), width: mw * 2 + 4, height: 6), Paint()..color = skin);
    final mouth = Path()
      ..moveTo(cx - mw, my)
      ..quadraticBezierTo(cx, my + 3.5, cx + mw, my);
    canvas.drawPath(mouth, ink..strokeWidth = 1.5);
  }

  // ---------------------------------------------------------------- SAÇ
  void _drawHair(Canvas canvas, FaceGeometry g, Paint fill, {required bool backLayer}) {
    const cx = FaceGeometry.cx;
    final hs = hair;
    final hairlineT = 0.17;
    final hy = g.y(hairlineT);
    final crownY = g.top - hs.top * 1.6;
    final fwHalf = g.halfAt(0.2);
    final sideX = fwHalf + 2 + hs.side * 0.7;
    final sideT = hs.sideDown;
    final sideBottomY = g.y(math.min(sideT, 1.1));
    double halfClamp(double t) => g.halfAt(math.min(t, 1.0));

    if (backLayer) {
      // Uzun saçın arkası: omuzlara doğru açılan kütle
      final outerBottom = math.max(halfClamp(sideT), fwHalf * 0.8) + hs.side + 6;
      final back = Path()
        ..moveTo(cx - outerBottom, sideBottomY)
        ..quadraticBezierTo(cx - sideX - 4, g.y(0.5), cx - sideX, g.y(0.15))
        ..lineTo(cx + sideX, g.y(0.15))
        ..quadraticBezierTo(cx + sideX + 4, g.y(0.5), cx + outerBottom, sideBottomY)
        ..close();
      canvas.drawPath(back, fill);
      return;
    }

    if (hs.bun) {
      canvas.drawCircle(Offset(cx, crownY - 7), 10, fill);
    }

    final peakX = cx + hs.peakShift * FaceGeometry.unit;
    final pw = sideX * 0.55 * hs.peakWidth;

    // Dış kontur
    final p = Path();
    final leftBottomOuter = cx - (halfClamp(math.min(sideT, 0.6)) + hs.side * 0.6 + 1);
    p.moveTo(leftBottomOuter, sideBottomY);
    p.lineTo(cx - sideX, g.y(0.22));
    p.cubicTo(cx - sideX, g.top - hs.top * 0.35, peakX - pw, crownY, peakX, crownY);
    p.cubicTo(peakX + pw, crownY, cx + sideX, g.top - hs.top * 0.35, cx + sideX, g.y(0.22));
    final rightBottomOuter = cx + (halfClamp(math.min(sideT, 0.6)) + hs.side * 0.6 + 1);
    p.lineTo(rightBottomOuter, sideBottomY);

    // İç kontur (saç çizgisi)
    final innerSideT = math.min(sideT, 1.0);
    final templeX = fwHalf * 0.86;
    p.lineTo(cx + halfClamp(innerSideT) - 3, sideBottomY);
    // sağ yan içten yukarı
    p.lineTo(cx + g.halfAt(0.3) - 3, g.y(0.3));
    p.lineTo(cx + templeX, hy);

    final fringeY = hy + hs.fringe * g.length * 0.16;
    if (hs.fringe > 0) {
      // Dağınık kakül: zikzak alt kenar
      const teeth = 7;
      for (var i = 1; i <= teeth; i++) {
        final x = cx + templeX - (2 * templeX) * i / teeth;
        final yy = i.isOdd ? fringeY + 2 : fringeY - 4;
        p.lineTo(x, i == teeth ? hy : yy);
      }
    } else if (hs.part) {
      p.quadraticBezierTo(cx, hy - 5, cx - templeX, hy + 1);
    } else {
      p.quadraticBezierTo(cx, hy - 7, cx - templeX, hy);
    }
    p.lineTo(cx - g.halfAt(0.3) + 3, g.y(0.3));
    p.lineTo(cx - halfClamp(innerSideT) + 3, sideBottomY);
    p.close();

    canvas.drawPath(p, fill);

    // Undercut: kazınmış yanların gölgesi
    if (hs.undercut) {
      final shade = Paint()..color = hairColor.withValues(alpha: 0.28);
      for (final d in [-1.0, 1.0]) {
        final r = Path()
          ..moveTo(cx + d * (fwHalf - 2), g.y(0.2))
          ..lineTo(cx + d * (sideX + 1), g.y(0.2))
          ..lineTo(cx + d * (g.halfAt(0.42) + 1), g.y(0.42))
          ..lineTo(cx + d * (g.halfAt(0.42) - 3), g.y(0.42))
          ..close();
        canvas.drawPath(r, shade);
      }
    }

    final strand = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    if (hs.slick) {
      for (var i = -2; i <= 2; i++) {
        final x0 = cx + i * templeX * 0.32;
        final l = Path()
          ..moveTo(x0, hy - 2)
          ..quadraticBezierTo(x0 + i * 2, crownY + hs.top * 0.25, peakX + i * pw * 0.35, crownY + 4);
        canvas.drawPath(l, strand);
      }
    } else if (hs.texture) {
      final rnd = math.Random(7);
      for (var i = 0; i < 9; i++) {
        final x0 = cx - templeX * 0.9 + rnd.nextDouble() * templeX * 1.8;
        final y0 = (hs.fringe > 0 ? fringeY - 6 : hy - 3) - rnd.nextDouble() * 4;
        final l = Path()
          ..moveTo(x0, y0)
          ..quadraticBezierTo(x0 + 3, (y0 + crownY) / 2, x0 + 6 + hs.peakShift * 20, crownY + 5 + rnd.nextDouble() * 4);
        canvas.drawPath(l, strand);
      }
    }

    if (hs.part) {
      final partX = cx - templeX * 0.45;
      final l = Path()
        ..moveTo(partX, hy - 1)
        ..quadraticBezierTo(partX - 2, (hy + crownY) / 2, partX + 4, crownY + hs.top * 0.35);
      canvas.drawPath(
        l,
        Paint()
          ..color = skin
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      // ayrımdan karşıya taranan saç çizgileri
      for (var i = 1; i <= 3; i++) {
        final s = Path()
          ..moveTo(partX + 4, hy - 4 - i * 4)
          ..quadraticBezierTo(cx + templeX * 0.4, crownY + 2 + i * 3, cx + sideX - 4, g.y(0.12) - i * 2);
        canvas.drawPath(s, strand);
      }
    }
  }

  // ---------------------------------------------------------------- SAKAL
  void _drawBeard(Canvas canvas, FaceGeometry g) {
    final b = beard;
    if (b.type == BeardType.none) return;
    const cx = FaceGeometry.cx;
    final fill = Paint()..color = b.stubble ? hairColor.withValues(alpha: 0.26) : hairColor;
    final my = g.y(0.72);
    final mw = g.halfAt(0.72) * 0.32;

    Path mustache() => Path()
      ..moveTo(cx - mw - 3, my + 1)
      ..quadraticBezierTo(cx - mw, g.y(0.64), cx, g.y(0.655))
      ..quadraticBezierTo(cx + mw, g.y(0.64), cx + mw + 3, my + 1)
      ..quadraticBezierTo(cx, my - 3, cx - mw - 3, my + 1)
      ..close();

    switch (b.type) {
      case BeardType.full:
        final p = Path();
        final c = b.cheekLine;
        // sol yanaktan çeneye, oradan sağ yanağa (kontur boyunca, dışa doğru uzatarak)
        final pts = <Offset>[];
        for (var t = c; t <= 1.0001; t += 0.04) {
          final grow = b.length * math.pow((t - c) / (1 - c), 1.4);
          final half = g.halfAt(math.min(t, 1.0));
          pts.add(Offset(cx - half - grow * 0.35, g.y(t) + grow * ((t - c) / (1 - c))));
        }
        final right = pts.reversed.map((o) => Offset(2 * cx - o.dx, o.dy)).toList();
        final outline = [...pts, Offset(cx, g.y(1) + b.length), ...right];
        FaceGeometry.catmullRom(outline, into: p);
        // üst kenar: yanaktan bıyığa
        p.quadraticBezierTo(cx + g.halfAt(c) * 0.55, g.y(c + 0.06), cx + mw + 6, g.y(0.63));
        p.quadraticBezierTo(cx, g.y(0.6), cx - mw - 6, g.y(0.63));
        p.quadraticBezierTo(cx - g.halfAt(c) * 0.55, g.y(c + 0.06), outline.first.dx, outline.first.dy);
        p.close();
        canvas.drawPath(p, fill);
        if (b.stubble) {
          final dot = Paint()..color = hairColor.withValues(alpha: 0.35);
          final rnd = math.Random(3);
          final bounds = p.getBounds();
          for (var i = 0; i < 160; i++) {
            final o = Offset(bounds.left + rnd.nextDouble() * bounds.width, bounds.top + rnd.nextDouble() * bounds.height);
            if (p.contains(o)) canvas.drawCircle(o, 0.55, dot);
          }
        }
        break;
      case BeardType.goatee:
        canvas.drawPath(mustache(), fill);
        final chin = Path()
          ..moveTo(cx - mw * 0.7, my + 5)
          ..quadraticBezierTo(cx, my + 2, cx + mw * 0.7, my + 5)
          ..quadraticBezierTo(cx + mw * 0.8, g.y(1) + b.length * 0.6, cx, g.y(1) + b.length)
          ..quadraticBezierTo(cx - mw * 0.8, g.y(1) + b.length * 0.6, cx - mw * 0.7, my + 5)
          ..close();
        canvas.drawPath(chin, fill);
        break;
      case BeardType.circle:
        final ring = Path()
          ..fillType = PathFillType.evenOdd
          ..addOval(Rect.fromLTRB(cx - mw - 7, g.y(0.625), cx + mw + 7, g.y(1) + b.length))
          ..addOval(Rect.fromCenter(center: Offset(cx, my + 1), width: mw * 2 + 2, height: 7));
        canvas.save();
        canvas.clipPath(g.facePath()..addRect(Rect.fromLTRB(0, g.y(0.9), 200, 240)));
        canvas.drawPath(ring, fill);
        canvas.restore();
        break;
      case BeardType.anchor:
        canvas.drawPath(mustache(), fill);
        final a = Path()
          ..moveTo(cx - mw - 10, g.y(0.86))
          ..quadraticBezierTo(cx, g.y(0.8), cx + mw + 10, g.y(0.86))
          ..quadraticBezierTo(cx + mw * 0.6, g.y(1), cx, g.y(1) + b.length)
          ..quadraticBezierTo(cx - mw * 0.6, g.y(1), cx - mw - 10, g.y(0.86))
          ..close();
        canvas.drawPath(a, fill);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, my + 7), width: 5, height: 7), fill);
        break;
      case BeardType.strap:
        final pts = <Offset>[];
        for (var t = 0.5; t <= 1.0001; t += 0.05) {
          pts.add(Offset(cx - g.halfAt(math.min(t, 1.0)), g.y(math.min(t, 1.0))));
        }
        final line = [...pts, ...pts.reversed.skip(1).map((o) => Offset(2 * cx - o.dx, o.dy))];
        canvas.drawPath(
          FaceGeometry.catmullRom(line),
          Paint()
            ..color = hairColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 + b.length
            ..strokeCap = StrokeCap.round,
        );
        break;
      case BeardType.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant PortraitPainter old) => old.outline != outline || old.hair != hair || old.beard != beard;
}

/// Sadece yüz hattını kesikli çizgiyle gösteren sade ikon (şekil kartları için).
class OutlinePainter extends CustomPainter {
  final FaceOutline outline;
  final Color color;
  final double strokeWidth;
  OutlinePainter(this.outline, {this.color = AppColors.accent, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final g = FaceGeometry(outline);
    final path = g.facePath();
    final b = path.getBounds();
    final s = math.min(size.width / (b.width + 8), size.height / (b.height + 8));
    canvas.save();
    canvas.translate(size.width / 2 - b.center.dx * s, size.height / 2 - b.center.dy * s);
    canvas.scale(s);
    canvas.drawPath(path, Paint()..color = AppColors.accent.withValues(alpha: 0.08));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / s
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      final dash = 7 / s * 1.6, gap = 4 / s * 1.6;
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
        d += dash + gap;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OutlinePainter old) => old.outline != outline || old.color != color;
}

/// Kolay kullanım için hazır widget.
class Portrait extends StatelessWidget {
  final FaceOutline outline;
  final HairSpec hair;
  final BeardSpec beard;
  final double size;
  const Portrait({super.key, required this.outline, this.hair = HairSpec.neutral, this.beard = BeardSpec.none, this.size = 120});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 200 / 180,
    child: CustomPaint(
      painter: PortraitPainter(outline: outline, hair: hair, beard: beard),
    ),
  );
}
