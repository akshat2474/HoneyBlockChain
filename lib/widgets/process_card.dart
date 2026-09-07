import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import 'honey_art.dart';

class ProcessCard extends StatelessWidget {
  const ProcessCard({
    super.key,
    required this.step,
    required this.title,
    required this.description,
    required this.art,
  });

  final String step;
  final String title;
  final String description;
  final HoneyArtType art;

  @override
  Widget build(BuildContext context) => Container(
        width: 280,
        constraints: const BoxConstraints(minHeight: 302),
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 22),
        decoration: BoxDecoration(
          color: HoneyColors.gold,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: HoneyColors.gold.withValues(alpha: .22), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            HoneyArt(type: art, size: 72, color: HoneyColors.brown),
            const SizedBox(height: 14),
            Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 11),
            Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .92), height: 1.42, fontSize: 13.5)),
          ],
        ),
      );
}
