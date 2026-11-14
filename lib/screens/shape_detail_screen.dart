import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/portrait_painter.dart';

class ShapeDetailScreen extends StatelessWidget {
  final FaceShape shape;
  final int initialTab;
  const ShapeDetailScreen({super.key, required this.shape, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(pinned: true, title: Text('${shape.name} yüz')),
            SliverToBoxAdapter(child: _Header(shape: shape)),
            SliverPersistentHeader(pinned: true, delegate: _TabBarDelegate()),
          ],
          body: TabBarView(
            children: [
              _HairTab(shape: shape),
              _BeardTab(shape: shape),
              _StyleTab(shape: shape),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FaceShape shape;
  const _Header({required this.shape});

  @override
  Widget build(BuildContext context) {
    final isMine = AppState.instance.myShape == shape.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 72, height: 88, child: CustomPaint(painter: OutlinePainter(shape.outline))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMine) const Padding(padding: EdgeInsets.only(bottom: 6), child: Tag('Senin yüz şeklin', accent: true)),
                    Text(shape.summary, style: const TextStyle(fontSize: 13.5, height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final t in shape.traits) Tag(t)]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_outlined, size: 18, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(shape.goal, style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(
    color: AppColors.bg,
    child: const TabBar(
      tabs: [
        Tab(text: 'Saç'),
        Tab(text: 'Sakal'),
        Tab(text: 'Stil'),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// ------------------------------------------------------------------ SAÇ
class _HairTab extends StatelessWidget {
  final FaceShape shape;
  const _HairTab({required this.shape});

  @override
  Widget build(BuildContext context) {
    final repo = StyleRepository.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        for (final r in shape.hair) ...[
          StyleCard(
            favKey: AppState.key('hair', r.id, shape.id),
            title: repo.hairStyles[r.id]!.name,
            tags: [repo.hairStyles[r.id]!.length, repo.hairStyles[r.id]!.care],
            why: r.why,
            portrait: Portrait(outline: shape.outline, hair: repo.hairStyles[r.id]!.spec, size: 92),
          ),
          const SizedBox(height: 10),
        ],
        AvoidCard(title: 'Kaçınılacaklar', text: shape.hairAvoid),
      ],
    );
  }
}

// ------------------------------------------------------------------ SAKAL
class _BeardTab extends StatelessWidget {
  final FaceShape shape;
  const _BeardTab({required this.shape});

  @override
  Widget build(BuildContext context) {
    final repo = StyleRepository.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        for (final r in shape.beard) ...[
          StyleCard(
            favKey: AppState.key('beard', r.id, shape.id),
            title: repo.beardStyles[r.id]!.name,
            tags: const [],
            why: r.why,
            portrait: Portrait(outline: shape.outline, beard: repo.beardStyles[r.id]!.spec, size: 92),
          ),
          const SizedBox(height: 10),
        ],
        AvoidCard(title: 'Kaçınılacaklar', text: shape.beardAvoid),
      ],
    );
  }
}

// ------------------------------------------------------------------ STİL
class _StyleTab extends StatelessWidget {
  final FaceShape shape;
  const _StyleTab({required this.shape});

  @override
  Widget build(BuildContext context) {
    final g = shape.style;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _GuideCard(icon: Icons.checkroom_outlined, title: 'Yaka ve üst giyim', items: g.collars),
        const SizedBox(height: 10),
        _GuideCard(icon: Icons.visibility_outlined, title: 'Gözlük çerçevesi', items: g.glasses),
        const SizedBox(height: 10),
        _GuideCard(icon: Icons.face_retouching_natural_outlined, title: 'Şapka', items: g.hats),
        const SizedBox(height: 10),
        AvoidCard(title: 'Kaçınılacaklar', text: g.avoid.join('\n')),
        const SizedBox(height: 22),
        const SectionTitle('Kombin fikirleri', subtitle: 'Yüz şekline uygun yaka ve aksesuarlarla'),
        for (var i = 0; i < shape.outfits.length; i++) ...[
          OutfitCard(outfit: shape.outfits[i], favKey: AppState.key('outfit', '$i', shape.id)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  const _GuideCard({required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) => SoftCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.check, size: 15, color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(it, style: const TextStyle(fontSize: 13.5, height: 1.4))),
              ],
            ),
          ),
      ],
    ),
  );
}

// ------------------------------------------------------------------ ORTAK KARTLAR
class StyleCard extends StatelessWidget {
  final String favKey, title, why;
  final List<String> tags;
  final Widget portrait;
  const StyleCard({super.key, required this.favKey, required this.title, required this.why, required this.tags, required this.portrait});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: portrait,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    FavoriteButton(favKey: favKey),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final t in tags) Tag(t)]),
                  const SizedBox(height: 8),
                ],
                Text(why, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final String favKey;
  const FavoriteButton({super.key, required this.favKey});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) {
      final fav = AppState.instance.isFavorite(favKey);
      return IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: fav ? 'Kaydedilenlerden çıkar' : 'Kaydet',
        onPressed: () => AppState.instance.toggleFavorite(favKey),
        icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? AppColors.accent : AppColors.muted, size: 22),
      );
    },
  );
}

class AvoidCard extends StatelessWidget {
  final String title, text;
  const AvoidCard({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.do_not_disturb_alt_outlined, size: 18, color: AppColors.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
              ),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 13, height: 1.45)),
            ],
          ),
        ),
      ],
    ),
  );
}

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final String favKey;
  const OutfitCard({super.key, required this.outfit, required this.favKey});

  @override
  Widget build(BuildContext context) => SoftCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(outfit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            FavoriteButton(favKey: favKey),
          ],
        ),
        Row(
          children: [
            for (final c in outfit.palette)
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final it in outfit.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text('·  $it', style: const TextStyle(fontSize: 13.5, height: 1.35)),
          ),
      ],
    ),
  );
}
