import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/portrait_painter.dart';
import 'shape_detail_screen.dart';

class ShapesScreen extends StatelessWidget {
  const ShapesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StyleRepository.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) => CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yüz şekilleri', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6)),
                    SizedBox(height: 6),
                    Text('Her şekil için saç, sakal ve stil önerilerini incele.', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                    SizedBox(height: 14),
                    _HowTo(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  for (final s in repo.shapes)
                    SoftCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShapeDetailScreen(shape: s))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(child: CustomPaint(painter: OutlinePainter(s.outline))),
                                if (AppState.instance.myShape == s.id) const Positioned(top: 0, right: 0, child: Tag('Sen', accent: true)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(s.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(s.traits.take(2).join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 2),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowTo extends StatelessWidget {
  const _HowTo();

  @override
  Widget build(BuildContext context) => SoftCard(
    color: AppColors.accentSoft,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aynada kendin ölçmek istersen', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text(
          '1. Alın genişliği  2. Elmacık kemikleri arası  3. Çene hattı genişliği  4. Saç çizgisinden çene ucuna uzunluk.\n'
          'En geniş yer ve uzunluk/genişlik oranı şeklini belirler.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
      ],
    ),
  );
}
