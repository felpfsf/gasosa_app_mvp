import 'package:flutter/widgets.dart';

class AppSpacing {
  /// 4 - Espaçamento entre elementos
  static const double xs = 4;

  /// 8 - Espaçamento entre elementos
  static const double sm = 8;

  /// 16 - Espaçamento entre elementos
  static const double md = 16;

  /// 24 - Espaçamento entre elementos
  static const double lg = 24;

  /// 32 - Espaçamento entre elementos
  static const double xl = 32;

  /// 12 - Espaçamento entre elementos
  static const EdgeInsets paddingSm = EdgeInsets.all(12);

  /// 16 - Espaçamento entre elementos
  static const EdgeInsets paddingMd = EdgeInsets.all(md);

  /// 24 - Espaçamento entre elementos
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  /// 8 - Padding horizontal entre elementos
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);

  /// 16 - Padding horizontal entre elementos
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);

  /// 16 - Padding horizontal entre elementos
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);

  /// 8 - Padding vertical entre elementos
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);

  /// 16 - Padding vertical entre elementos
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);

  /// 24 - Padding vertical entre elementos
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);

  /// 6 - Raio de borda pequeno
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(6));

  /// 12 - Raio de borda médio
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));

  /// 16 - Raio de borda grande
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));

  /// 20 - Raio de borda grande
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(20));

  /// 4 - Espaçamento entre widgets
  static const SizedBox gap4 = SizedBox(height: 4);

  /// 8 - Espaçamento entre widgets
  static const SizedBox gap8 = SizedBox(height: 8);

  /// 16 - Espaçamento entre widgets
  static const SizedBox gap16 = SizedBox(height: 16);

  /// 24 - Espaçamento entre widgets
  static const SizedBox gap24 = SizedBox(height: 24);

  /// 4 - Espaçamento entre widgets
  static const SizedBox gapX4 = SizedBox(width: 4);

  /// 8 - Espaçamento entre widgets
  static const SizedBox gapX8 = SizedBox(width: 8);

  /// 16 - Espaçamento entre widgets
  static const SizedBox gapX16 = SizedBox(width: 16);

  /// 24 - Espaçamento entre widgets
  static const SizedBox gapX24 = SizedBox(width: 24);
}
