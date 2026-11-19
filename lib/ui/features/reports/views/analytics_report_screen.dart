import 'package:flutter/material.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/core/theme/app_typography.dart';

class AnalyticsReportScreen extends StatelessWidget {
  final bool showBackButton;

  const AnalyticsReportScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Reports',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.ssGold.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 40,
                  color: AppColors.ssGoldDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Reports Available',
                style: AppTypography.titleMedium.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reports section is currently clean. No data is being displayed.',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
