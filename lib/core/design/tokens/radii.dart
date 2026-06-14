import 'package:flutter/widgets.dart';

/// Corner-radius tokens.
abstract final class AppRadii {
  const AppRadii._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 28;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(lg));
}
