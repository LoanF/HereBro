import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static const Radius defaultRadius = Radius.circular(12);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.mainBackground,
      primaryColor: AppColors.mainColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.mainColor,
        secondary: AppColors.secondaryColor,
        error: AppColors.error,
        surface: AppColors.secondaryBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.secondaryBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.mainText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.mainText),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.mainText),
        bodyMedium: TextStyle(color: AppColors.secondaryText),
        bodySmall: TextStyle(color: AppColors.secondaryText),
        titleLarge: TextStyle(
          color: AppColors.mainText,
          fontWeight: FontWeight.bold,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(defaultRadius),
        ),
        textTheme: ButtonTextTheme.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.secondaryButton;
            }
            return AppColors.mainColor;
          }),
          foregroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.mainText,
          ),
          shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(defaultRadius),
            ),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryButton,
          foregroundColor: AppColors.mainText,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(defaultRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.mainColor,
        foregroundColor: AppColors.black,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.thirdBackground,
        hintStyle: TextStyle(color: AppColors.secondaryText),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: AppColors.mainColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        indicatorColor: AppColors.mainColor,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.black);
          }
          return const IconThemeData(color: AppColors.secondaryText);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.mainText,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(color: AppColors.secondaryText);
        }),
      ),
    );
  }
}
