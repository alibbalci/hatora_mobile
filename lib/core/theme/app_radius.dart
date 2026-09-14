import 'package:flutter/material.dart';

/// TR: Tek bir köşe yarıçapı ölçeği; her bileşen kendi değerini icat etmez.
/// EN: One corner-radius scale so components never invent their own.
abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const sheet = 24.0;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}
