import 'dart:io';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../services/app_state.dart';
import '../services/face_analyzer.dart';
import '../theme.dart';
import '../widgets/portrait_painter.dart';
import 'shape_detail_screen.dart';

class AnalyzeScreen extends StatefulWidget {
  final String imagePath;
  const AnalyzeScreen({super.key, required this.imagePath});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  Size? _imageSize;
  AnalysisResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final img = await decodeImageFromList(bytes);
      final size = Size(img.width.toDouble(), img.height.toDouble());
      img.dispose();
      if (mounted) setState(() => _imageSize = size);
      final result = await FaceShapeAnalyzer().analyzeFile(widget.imagePath);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e is AnalysisException ? e.message : 'Analiz sırasında bir hata oluştu: $e');
    }
  }

  void _openShape(FaceShape shape) {
    AppState.instance.setMyShape(shape.id);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ShapeDetailScreen(shape: shape)));
  }

  Future<void> _chooseManually() async {
    final repo = StyleRepository.instance;
    final picked = await showModalBottomSheet<FaceShape>(
      context: context,
      backgroundColor: AppColors.bg,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yüz şeklini seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final s in repo.shapes)
                    SoftCard(
                      padding: const EdgeInsets.all(10),
                      onTap: () => Navigator.pop(context, s),
                      child: Column(
                        children: [
                          Expanded(
                            child: CustomPaint(painter: OutlinePainter(s.outline), size: Size.infinite),
                          ),
                          const SizedBox(height: 6),
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) _openShape(picked);
  }

  @override
  Widget build(BuildContext context) {
    final repo = StyleRepository.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Yüz analizi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: _imageSize == null ? 3 / 4 : _imageSize!.width / _imageSize!.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.imagePath), fit: BoxFit.fill),
                  if (_result != null && _imageSize != null) CustomPaint(painter: _OverlayPainter(_result!, _imageSize!)),
                  if (_result == null && _error == null)
                    Container(
                      color: Colors.white.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2.4),
                          SizedBox(height: 14),
                          Text('Yüz hattı ölçülüyor…', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            SoftCard(
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, style: const TextStyle(height: 1.4))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Başka fotoğraf dene')),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _chooseManually, child: const Text('Şekli kendim seçeceğim')),
          ],
          if (_result != null) ..._resultSection(repo, _result!),
        ],
      ),
    );
  }

  List<Widget> _resultSection(StyleRepository repo, AnalysisResult r) {
    final best = repo.shape(r.bestShape);
    final m = r.measurements;
    return [
      SoftCard(
        child: Row(
          children: [
            SizedBox(width: 64, height: 76, child: CustomPaint(painter: OutlinePainter(best.outline))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yüz şeklin büyük ihtimalle', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(best.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  Text(
                    '%${(r.scores.first.probability * 100).round()} uyum',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (r.warning != null) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(r.warning!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ),
          ],
        ),
      ],
      const SizedBox(height: 18),
      const SectionTitle('Diğer olasılıklar'),
      for (final s in r.scores.skip(1).take(3))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(repo.shape(s.shapeId).name, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: s.probability,
                    minHeight: 8,
                    backgroundColor: AppColors.line,
                    color: AppColors.accent,
                  ),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '%${(s.probability * 100).round()}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 10),
      const SectionTitle('Ölçümler', subtitle: 'Elmacık genişliğine göre oranlar'),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
        children: [
          _Metric('Uzunluk / genişlik', m.lengthRatio),
          _Metric('Alın / elmacık', m.foreheadRatio),
          _Metric('Çene / elmacık', m.jawRatio),
          _Metric('Çene ucu daralması', m.chinTaper),
        ],
      ),
      const SizedBox(height: 14),
      const Text(
        'Bu sonuç fotoğraftaki yüz hattından yapılan bir tahmindir. Işık, açı ve saç alnı kapatıyorsa sonuç değişebilir; '
        'uymadığını düşünürsen şekli kendin seçebilirsin.',
        style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.45),
      ),
      const SizedBox(height: 18),
      FilledButton(onPressed: () => _openShape(best), child: Text('${best.name} yüz için önerileri gör')),
      const SizedBox(height: 10),
      OutlinedButton(onPressed: _chooseManually, child: const Text('Şekli kendim seçeceğim')),
    ];
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final double value;
  const _Metric(this.label, this.value);

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    ),
  );
}

/// Fotoğrafın üzerine yüz konturunu ve ölçüm çizgilerini çizer.
class _OverlayPainter extends CustomPainter {
  final AnalysisResult r;
  final Size imageSize;
  _OverlayPainter(this.r, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / imageSize.width, sy = size.height / imageSize.height;
    Offset map(Offset p) => Offset(p.dx * sx, p.dy * sy);

    final contour = FaceGeometry.catmullRom(r.contour.map(map).toList(), closed: true);
    canvas.drawPath(
      contour,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.drawPath(
      contour,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.4;
    for (final l in r.lines) {
      final a = map(l.a), b = map(l.b);
      canvas.drawLine(a, b, linePaint);
      canvas.drawCircle(a, 3, Paint()..color = AppColors.accent);
      canvas.drawCircle(b, 3, Paint()..color = AppColors.accent);
      if (l.label != 'Uzunluk') {
        final tp = TextPainter(
          text: TextSpan(
            text: ' ${l.label} ',
            style: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600, backgroundColor: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, b + const Offset(6, -8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => old.r != r;
}
