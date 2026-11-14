import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repository.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/portrait_painter.dart';
import 'analyze_screen.dart';
import 'shape_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onBrowseShapes;
  const HomeScreen({super.key, required this.onBrowseShapes});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (file == null || !context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnalyzeScreen(imagePath: file.path)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fotoğraf alınamadı: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = StyleRepository.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final myId = AppState.instance.myShape;
          final my = myId == null ? null : repo.shape(myId);
          final heroShape = my ?? repo.shape('oval');
          final heroHair = repo.hairStyles[heroShape.hair.first.id]!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const _Brand(),
              const SizedBox(height: 22),
              const Text(
                'Yüzüne en çok\nyakışanı bul.',
                style: TextStyle(fontSize: 32, height: 1.12, fontWeight: FontWeight.w700, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selfie çek; yüz şeklini ölçelim, sana uygun saç kesimi, sakal ve kombin fikirlerini çıkaralım.',
                style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 20),
              SoftCard(
                color: AppColors.accentSoft,
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 0),
                onTap: my == null
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShapeDetailScreen(shape: my))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              my == null ? 'NASIL ÇALIŞIR' : 'YÜZ ŞEKLİN',
                              style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              my == null ? '1 fotoğraf,\n6 yüz şekli,\nonlarca fikir.' : my.name,
                              style: TextStyle(fontSize: my == null ? 19 : 30, fontWeight: FontWeight.w700, height: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              my == null
                                  ? 'Alın, elmacık ve çene oranların ölçülür.'
                                  : 'Önerilen: ${heroHair.name}\nÖnerilerini görmek için dokun →',
                              style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Portrait(outline: heroShape.outline, hair: heroHair.spec, size: 132),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _pick(context, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(my == null ? 'Selfie çek' : 'Yeniden analiz et'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _pick(context, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeriden seç'),
              ),
              const SizedBox(height: 26),
              const SectionTitle('İyi bir fotoğraf için'),
              const Row(
                children: [
                  Expanded(
                    child: _Tip(icon: Icons.straighten, text: 'Saçını alnından geriye çek'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _Tip(icon: Icons.center_focus_strong_outlined, text: 'Kameraya düz bak'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _Tip(icon: Icons.wb_sunny_outlined, text: 'Önden gelen ışık'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(child: SectionTitle('Yüz şekilleri')),
                  TextButton(
                    onPressed: onBrowseShapes,
                    child: const Text('Tümü', style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: repo.shapes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final s = repo.shapes[i];
                    return SizedBox(
                      width: 96,
                      child: SoftCard(
                        padding: const EdgeInsets.all(10),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShapeDetailScreen(shape: s))),
                        child: Column(
                          children: [
                            Expanded(
                              child: CustomPaint(painter: OutlinePainter(s.outline), size: Size.infinite),
                            ),
                            const SizedBox(height: 6),
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(6),
        child: CustomPaint(painter: OutlinePainter(StyleRepository.instance.shape('oval').outline, color: Colors.white, strokeWidth: 1.6)),
      ),
      const SizedBox(width: 10),
      const Text('FaceFit', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
    ],
  );
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontSize: 12.5, height: 1.3)),
      ],
    ),
  );
}
