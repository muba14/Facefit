import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/portrait_painter.dart';
import 'shape_detail_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StyleRepository.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final favs = AppState.instance.favorites;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              const Text('Kaydedilenler', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6)),
              const SizedBox(height: 6),
              const Text('Berbere göstermek için beğendiğin stiller burada.', style: TextStyle(color: AppColors.muted, fontSize: 14)),
              const SizedBox(height: 18),
              if (favs.isEmpty)
                SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite_border, size: 34, color: AppColors.accent),
                      const SizedBox(height: 12),
                      const Text('Henüz bir şey kaydetmedin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
                      const Text(
                        'Saç, sakal veya kombin kartlarındaki kalbe dokun.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              for (final key in favs) ...[_SavedTile(favKey: key, repo: repo), const SizedBox(height: 10)],
            ],
          );
        },
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  final String favKey;
  final StyleRepository repo;
  const _SavedTile({required this.favKey, required this.repo});

  @override
  Widget build(BuildContext context) {
    // "kind:styleId@shapeId"
    final kind = favKey.split(':').first;
    final rest = favKey.substring(kind.length + 1);
    final styleId = rest.split('@').first;
    final shape = repo.shapes.where((s) => s.id == rest.split('@').last).firstOrNull;
    if (shape == null) return const SizedBox.shrink();

    late final String title, subtitle;
    late final Widget leading;
    late final int tab;
    switch (kind) {
      case 'hair':
        final h = repo.hairStyles[styleId];
        if (h == null) return const SizedBox.shrink();
        title = h.name;
        subtitle = 'Saç · ${shape.name} yüz';
        leading = Portrait(outline: shape.outline, hair: h.spec, size: 56);
        tab = 0;
      case 'beard':
        final b = repo.beardStyles[styleId];
        if (b == null) return const SizedBox.shrink();
        title = b.name;
        subtitle = 'Sakal · ${shape.name} yüz';
        leading = Portrait(outline: shape.outline, beard: b.spec, size: 56);
        tab = 1;
      default:
        final i = int.tryParse(styleId) ?? 0;
        if (i >= shape.outfits.length) return const SizedBox.shrink();
        final o = shape.outfits[i];
        title = o.name;
        subtitle = 'Kombin · ${shape.name} yüz';
        leading = SizedBox(
          width: 56,
          height: 67,
          child: Wrap(
            spacing: 3,
            runSpacing: 3,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              for (final c in o.palette.take(4))
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                ),
            ],
          ),
        );
        tab = 2;
    }

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShapeDetailScreen(shape: shape, initialTab: tab),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: leading,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
          FavoriteButton(favKey: favKey),
        ],
      ),
    );
  }
}
