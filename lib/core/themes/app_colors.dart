import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color white = Color(0xFFFAFAFA);
  static const Color darkWhite = Color(0xFFECECEC);

  static const Color black = Color(0xFF121212);
  static const Color lightBlack = Color(0xFF1E1E1E);
  static const Color darkGrey = Color(0xFF242424);

  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color grey1 = Color(0xFF8A8A8A);
  static const Color grey2 = Color(0xFFBDBDBD);

  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color darkBlue = Color(0xFF1565C0);

  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF2E7D32);

  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color success = primaryGreen;

  // Dark theme specific
  static const Color mainBackground = black;
  static const Color secondaryBackground = lightBlack;
  static const Color thirdBackground = darkGrey;

  static const Color mainText = darkWhite;
  static const Color secondaryText = grey2;

  static const Color mainColor = primaryBlue;
  static const Color secondaryColor = primaryGreen;

  static const Color secondaryButton = lightBlue;
  static const Color linkAction = lightBlue;
}
