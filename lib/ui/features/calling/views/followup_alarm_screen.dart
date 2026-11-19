import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_crm_dialer/core/platform/call_channel.dart';
import 'package:sales_crm_dialer/domain/entities/lead.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/alarm_sound_service.dart';
import '../../../../core/services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FollowupAlarmScreen extends StatefulWidget {
  final String leadJson;
  const FollowupAlarmScreen({super.key, required this.leadJson});

  @override
  State<FollowupAlarmScreen> createState() => _FollowupAlarmScreenState();
}

class _FollowupAlarmScreenState extends State<FollowupAlarmScreen>
    with SingleTickerProviderStateMixin {
  late Lead lead;
  late AnimationController _pulseController;
  StreamSubscription? _callEventSub;

  @override
  void initState() {
    super.initState();
    try {
      final decoded = jsonDecode(widget.leadJson);
      lead = Lead.fromJson(decoded);
    } catch (e) {
      lead = Lead(
        id: 'error',
        fullName: 'Unknown Contact',
        phone: 'Unknown',
        status: LeadStatus.newLead,
        priority: LeadPriority.medium,
        source: 'Unknown',
        createdAt: DateTime.now(),
      );
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Listen for hardware volume key presses (Volume Down, Volume Up, Mute)
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);

    // Listen for native volume button broadcast from MainActivity
    _callEventSub = CallChannel.callEvents.listen((event) {
      if (event.type == 'SILENCE_ALARM') {
        _silenceAlarm();
      }
    });

    // Start loud alarm audio and vibration immediately
    AlarmSoundService.startRinging();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.audioVolumeDown ||
          key == LogicalKeyboardKey.audioVolumeUp ||
          key == LogicalKeyboardKey.audioVolumeMute) {
        _silenceAlarm();
        return true;
      }
    }
    return false;
  }

  void _silenceAlarm() {
    if (!AlarmSoundService.isSilenced) {
      AlarmSoundService.silenceRinging();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _callEventSub?.cancel();
    _pulseController.dispose();
    AlarmSoundService.stopRinging();
    super.dispose();
  }

  Future<void> _handleCallNow() async {
    await AlarmSoundService.stopRinging();
    if (!mounted) return;
    context.go(AppRoutes.home);
    await AppRouter.callVm.initiateCall(lead: lead);
  }

  Future<void> _handleSnooze({int minutes = 10}) async {
    await AlarmSoundService.stopRinging();
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    await NotificationService.scheduleFollowupAlarm(lead, snoozeTime);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.snooze_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Alarm snoozed for $minutes minutes'),
          ],
        ),
        backgroundColor: AppColors.ssGoldDark,
        duration: const Duration(seconds: 3),
      ),
    );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleDismiss() async {
    await AlarmSoundService.stopRinging();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSilenced = AlarmSoundService.isSilenced;

    return WillPopScope(
      onWillPop: () async {
        await AlarmSoundService.stopRinging();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8F2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),

                // ── Flashing Alarm / Silenced Badge ─────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _silenceAlarm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSilenced ? const Color(0xFFF1F5F9) : const Color(0xFFFFECE5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSilenced ? const Color(0xFF94A3B8) : AppColors.error.withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSilenced ? Icons.volume_off_rounded : Icons.notifications_active_rounded,
                            size: 16,
                            color: isSilenced ? const Color(0xFF64748B) : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSilenced ? 'ALARM SILENCED' : 'CALL BACK ALARM RINGING',
                            style: AppTypography.labelSmall.copyWith(
                              color: isSilenced ? const Color(0xFF475569) : AppColors.error,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Animated Pulsing Alarm Icon ──────────────────
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple Ring 1
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 80 + (_pulseController.value * 60),
                              height: 80 + (_pulseController.value * 60),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.ssGold
                                    .withOpacity((1.0 - _pulseController.value) * 0.25),
                              ),
                            );
                          },
                        ),
                        // Inner circle
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.ssGold.withAlpha(35),
                            border: Border.all(
                              color: AppColors.ssGold,
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.alarm_on_rounded,
                            size: 48,
                            color: AppColors.ssGoldDark,
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .rotate(begin: -0.05, end: 0.05, duration: 250.ms)
                              .scaleXY(begin: 1.0, end: 1.08, duration: 500.ms),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Title & Subtitle ─────────────────────────────
                Text(
                  'Follow-up Reminder',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'It is time to contact',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Lead Card ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.borderRadiusLg,
                    border: Border.all(
                      color: AppColors.ssGold.withAlpha(60),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ssGold.withAlpha(25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        lead.fullName.isNotEmpty ? lead.fullName : 'Unknown Contact',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.ssGoldDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_rounded,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            lead.phone,
                            style: AppTypography.titleMedium.copyWith(
                              color: const Color(0xFF5D4037),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (lead.projectName != null &&
                          lead.projectName!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_city_rounded,
                                  size: 14, color: AppColors.ssGoldDark),
                              const SizedBox(width: 4),
                              Text(
                                lead.projectName!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.ssGoldDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── Action Buttons ───────────────────────────────
                // 1. CALL NOW (Primary)
                ElevatedButton(
                  onPressed: _handleCallNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'CALL NOW',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0),
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02), duration: 800.ms),

                const SizedBox(height: 12),

                // 2. Snooze & Silence / Dismiss Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleSnooze(minutes: 10),
                        icon: const Icon(Icons.snooze_rounded, size: 18),
                        label: const Text('Snooze (10m)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ssGoldDark,
                          side: const BorderSide(
                              color: AppColors.ssGold, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderRadiusMd,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleDismiss,
                        icon: const Icon(Icons.notifications_off_rounded, size: 18, color: AppColors.error),
                        label: const Text('Silence Ring'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          side: BorderSide(color: AppColors.error.withAlpha(120), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderRadiusMd,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
