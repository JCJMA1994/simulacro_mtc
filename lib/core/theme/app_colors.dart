import 'package:flutter/material.dart';

/// Paleta de colores oficial del sistema de diseño (MTC Simulacro).
abstract final class AppColors {
  static const Color primary = Color(0xFF0E4C8A); // Azul institucional MTC
  static const Color primaryDark = Color(0xFF09315A);
  static const Color primaryLight = Color(0xFF1B6BB8);
  static const Color primaryAccent = Color(0xFF2575FC);

  static const Color success = Color(0xFF1D7A4F); // Verde acierto
  static const Color successLight = Color(0xFFE8F5EE);
  static const Color error = Color(0xFFB3261E); // Rojo error
  static const Color errorLight = Color(0xFFFDECEB);
  static const Color warning = Color(0xFFB87407); // Ámbar alerta / tiempo crítico
  static const Color warningLight = Color(0xFFFEF5E7);

  static const Color background = Color(0xFFF7F6F2); // Fondo cálido neutro refinado
  static const Color surface = Color(0xFFFFFFFF); // Superficie limpia
  static const Color surfaceSubtle = Color(0xFFF0EFEA);
  static const Color textPrimary = Color(0xFF1C1B19); // Texto principal
  static const Color textSecondary = Color(0xFF6B6A65); // Texto secundario
  static const Color textMuted = Color(0xFF9E9C96);
  static const Color border = Color(0xFFE2DFD6); // Borde sutil
  static const Color divider = Color(0xFFEBE8E0);

  // Degradados de diseño premium
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E4C8A), Color(0xFF1B6BB8)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF09315A), Color(0xFF0E4C8A)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D7A4F), Color(0xFF2EA069)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB87407), Color(0xFFE08E0B)],
  );

  // Sombras sutiles
  static List<BoxShadow> softShadow({Color? color, double opacity = 0.05}) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];
}
