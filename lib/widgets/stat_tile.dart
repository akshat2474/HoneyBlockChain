import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        width: 158,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(color: HoneyColors.cream, shape: BoxShape.circle),
              child: Icon(icon, color: HoneyColors.goldDark, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: HoneyColors.muted)),
          ],
        ),
      );
}
