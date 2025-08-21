import 'package:flutter/material.dart';

class LogoHero extends StatelessWidget {
  const LogoHero({
    super.key,
    this.tag = 'app-logo',
    this.assetPath = 'assets/images/app_logo_novo.png',
    this.size = 256.0,
  });

  final String tag;
  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
      ),
    );
  }
}
