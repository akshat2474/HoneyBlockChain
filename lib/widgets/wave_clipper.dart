import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height * .55);
    path.cubicTo(
      size.width * .18,
      size.height * .95,
      size.width * .33,
      size.height * .2,
      size.width * .52,
      size.height * .55,
    );
    path.cubicTo(
      size.width * .70,
      size.height * .90,
      size.width * .84,
      size.height * .28,
      size.width,
      size.height * .55,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
