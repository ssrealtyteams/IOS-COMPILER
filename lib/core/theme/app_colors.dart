// ─── App Colors ──────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary (Gold)
  static const primary = ssGold;
  static const primaryLight = ssGoldLight;
  static const primaryDark = ssGoldDark;
  static const primarySurface = Color(0xFF2A2411);

  // Secondary
  static const secondary = Color(0xFF00ACC1);
  static const secondaryLight = Color(0xFF26C6DA);
  static const secondarySurface = Color(0xFF182B2D);

  // Semantic
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFF43A047);
  static const successSurface = Color(0xFF1B2E1E);

  // ... (keep warnings/errors same mostly)
  static const warning = Color(0xFFE65100);
  static const warningLight = Color(0xFFF57C00);
  static const warningSurface = Color(0xFF332011);

  static const error = Color(0xFFC62828);
  static const errorLight = Color(0xFFE53935);
  static const errorSurface = Color(0xFF331414);

  static const info = ssGold;
  static const infoLight = ssGoldLight;
  static const infoSurface = Color(0xFF2A2411);

  // Hot / Warm / Cold Lead
  static const hot = Color(0xFFBF360C);
  static const hotSurface = Color(0xFF3B1E16);
  static const warm = Color(0xFFE65100);
  static const warmSurface = Color(0xFF332011);
  static const cold = ssGold;
  static const coldSurface = Color(0xFF2A2411);

  // Neutrals (Light Golden Brown Theme)
  static const background = Color(0xFFFDF8F1); // Light golden beige
  static const surface = Color(0xFFFFFFFF); // White cards for contrast
  static const surfaceVariant = Color(0xFFF5EBE1); // Lighter brown/beige
  static const border = Color(0xFFE8D5B5); // Golden brown border
  static const borderLight = Color(0xFFF5EBE1);

  // Text (Dark Brown for readability on light golden theme)
  static const textPrimary = Color(0xFF3E2723); // Deep dark brown
  static const textSecondary = Color(0xFF5D4037); // Medium brown
  static const textTertiary = Color(0xFF8D6E63);
  static const textOnPrimary = Color(0xFFFFFFFF); // White text on gold buttons
  static const textDisabled = Color(0xFFD7CCC8);

  // Gradients
  static const gradientStart = Color(0xFFEAD8B1);
  static const gradientEnd = Color(0xFFC9A227);



  // SS Realty Theme
  static const ssGold = Color(0xFFC9A227);
  static const ssGoldLight = Color(0xFFF0D060);
  static const ssGoldDark = Color(0xFFB8860B);
  static const ssDarkBackground = Color(0xFF141200);

  // Status colors
  static Color statusColor(String status) {
    return switch (status.toLowerCase()) {
      'new' => const Color(0xFF1565C0),
      'contacted' => const Color(0xFF6A1B9A),
      'interested' => const Color(0xFF2E7D32),
      'hot' || 'hot_lead' => const Color(0xFFBF360C),
      'warm' || 'warm_lead' => const Color(0xFFE65100),
      'cold' || 'cold_lead' => const Color(0xFF37474F),
      'visit_scheduled' => const Color(0xFF00838F),
      'visit_done' => const Color(0xFF1B5E20),
      'closed_won' => const Color(0xFF1B5E20),
      'closed_lost' || 'lost' => const Color(0xFFC62828),
      'invalid' => const Color(0xFF78909C),
      _ => const Color(0xFF475569),
    };
  }

  static Color priorityColor(String priority) {
    return switch (priority.toLowerCase()) {
      'high' => error,
      'medium' => warning,
      'low' => success,
      _ => textSecondary,
    };
  }

  static Color dispositionColor(String disposition) {
    return switch (disposition.toLowerCase()) {
      'connected' || 'interested' || 'hot_lead' || 'visit_done' => successLight,
      'not_connected' || 'wrong_number' || 'lost' => errorLight,
      'busy' || 'ringing' || 'warm_lead' => warningLight,
      'switched_off' || 'not_reachable' || 'cold_lead' => textSecondary,
      'visit_scheduled' || 'followup' => secondaryLight,
      'closed' || 'booking_done' || 'closed_won' => const Color(0xFFC9A227),
      _ => textSecondary,
    };
  }
}
