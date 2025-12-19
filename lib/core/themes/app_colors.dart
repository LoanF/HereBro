import 'package:flutter/material.dart';

abstract final class AppColors {
  // Base Colors - Un fond sombre bleuté profond (plus moderne que le noir pur)
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B);    // Slate 800
  static const Color surfaceLight = Color(0xFF334155); // Slate 700

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);   // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textTertiary = Color(0xFF64748B);  // Slate 500

  // Brand Colors - Un violet électrique couplé à un bleu cyan
  static const Color primary = Color(0xFF6366F1);      // Indigo 500
  static const Color primaryDark = Color(0xFF4338CA);  // Indigo 700
  static const Color accent = Color(0xFF06B6D4);       // Cyan 500

  // Functional Colors
  static const Color error = Color(0xFFEF4444);        // Red 500
  static const Color success = Color(0xFF10B981);      // Emerald 500
  static const Color warning = Color(0xFFF59E0B);      // Amber 500

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}