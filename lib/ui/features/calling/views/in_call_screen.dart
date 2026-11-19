import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../view_models/call_view_model.dart';

class InCallScreen extends StatelessWidget {
  const InCallScreen({
    super.key,
    required this.callViewModel,
  });

  final CallViewModel callViewModel;

  @override
  Widget build(BuildContext context) {
    final vm = callViewModel;
    final lead = vm.activeLead;
    final phone = vm.activePhoneNumber ?? lead?.phone ?? 'Unknown';
    final name = lead?.fullName ?? 'Lead $phone';
    final project = (lead?.projectName != null && lead!.projectName!.isNotEmpty) ? lead.projectName! : 'Direct Dial';
    final unit = lead?.unitType;

    final isDialing = vm.state == CallViewState.dialing || vm.state == CallViewState.initiating;
    final isConnected = vm.state == CallViewState.connected;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090D16),
              Color(0xFF0F172A),
              Color(0xFF0B1120),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Header Bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // CRM Calling + Recording Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155), width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 700.ms, begin: 0.3, end: 1.0),
                              const SizedBox(width: 6),
                              const Text(
                                'REC ON',
                                style: TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD97706).withAlpha(100), width: 0.8),
                          ),
                          child: const Text(
                            'CRM DIALER',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Minimize to Floating Pill Button
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 28),
                      tooltip: 'Minimize to Floating Bar',
                      onPressed: () => vm.toggleMinimized(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Middle Main Area (Avatar OR Keypad) ──────────────────────────
              Expanded(
                child: vm.showKeypad
                    ? _buildInCallKeypad(vm)
                    : _buildContactInfo(name, phone, project, unit, isDialing, isConnected, vm),
              ),

              // ── In-Call Action Control Buttons (Mute, Keypad, Speaker) ──────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Button
                    _buildInCallControlButton(
                      icon: vm.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: vm.isMuted ? 'Muted' : 'Mute',
                      isActive: vm.isMuted,
                      activeColor: const Color(0xFFEF4444),
                      onTap: () => vm.toggleMute(),
                    ),

                    // Keypad Toggle Button
                    _buildInCallControlButton(
                      icon: Icons.dialpad_rounded,
                      label: 'Keypad',
                      isActive: vm.showKeypad,
                      activeColor: const Color(0xFF38BDF8),
                      onTap: () => vm.toggleKeypad(),
                    ),

                    // Speaker Button
                    _buildInCallControlButton(
                      icon: vm.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      label: vm.isSpeakerOn ? 'Speaker On' : 'Speaker',
                      isActive: vm.isSpeakerOn,
                      activeColor: const Color(0xFF38BDF8),
                      onTap: () => vm.toggleSpeaker(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Bottom Call Action Button(s) (Accept / Decline for Incoming OR Cut Call for Connected/Outgoing) ──
              Padding(
                padding: const EdgeInsets.only(bottom: 28, left: 32, right: 32),
                child: (vm.isIncoming && !isConnected)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Decline Call Button
                          _buildIncomingCallButton(
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            color: const Color(0xFFDC2626),
                            onTap: () => vm.rejectCall(),
                          ),
                          // Accept / Pick Call Button
                          _buildIncomingCallButton(
                            icon: Icons.call_rounded,
                            label: 'Accept',
                            color: const Color(0xFF10B981),
                            onTap: () => vm.answerCall(),
                            isPulse: true,
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () => vm.hangUpCall(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 10,
                            shadowColor: const Color(0xFFDC2626).withAlpha(150),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Cut Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPulse = false,
  }) {
    Widget buttonWidget = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(140),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 34),
        ),
      ),
    );

    if (isPulse) {
      buttonWidget = buttonWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(duration: 800.ms, begin: const Offset(0.94, 0.94), end: const Offset(1.08, 1.08));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buttonWidget,
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Contact Info & Pulsing Avatar ──────────────────────────────────────────
  Widget _buildContactInfo(
    String name,
    String phone,
    String project,
    String? unit,
    bool isDialing,
    bool isConnected,
    CallViewModel vm,
  ) {
    final initials = _safeInitials(name);
    final hasUnit = unit != null && unit.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Pulsing Avatar Ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulsing Glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isConnected ? const Color(0xFF10B981) : const Color(0xFFD97706)).withAlpha(30),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    duration: 1200.ms,
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.15, 1.15),
                  ),

              // Avatar Circle
              Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF334155), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withAlpha(80),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Lead Full Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Phone Number
          Text(
            phone,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 14),

          // Project & Unit Requirement Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business_rounded, size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  project,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasUnit) ...[
                  const SizedBox(width: 8),
                  Container(width: 3, height: 3, decoration: const BoxDecoration(color: Color(0xFF64748B), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Icon(Icons.bed_rounded, size: 14, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Call Status / Live Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isConnected
                  ? const Color(0xFF10B981).withAlpha(30)
                  : (vm.isIncoming ? const Color(0xFF10B981).withAlpha(25) : const Color(0xFFF59E0B).withAlpha(25)),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isConnected
                    ? const Color(0xFF10B981).withAlpha(100)
                    : (vm.isIncoming ? const Color(0xFF10B981).withAlpha(80) : const Color(0xFFF59E0B).withAlpha(80)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected
                      ? Icons.phone_in_talk_rounded
                      : (vm.isIncoming ? Icons.ring_volume_rounded : Icons.ring_volume_rounded),
                  size: 18,
                  color: isConnected
                      ? const Color(0xFF10B981)
                      : (vm.isIncoming ? const Color(0xFF34D399) : const Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected
                      ? vm.durationDisplay
                      : (vm.isIncoming ? 'Incoming Call...' : (isDialing ? 'Calling...' : 'Ringing...')),
                  style: TextStyle(
                    color: isConnected
                        ? const Color(0xFF34D399)
                        : (vm.isIncoming ? const Color(0xFF34D399) : const Color(0xFFFBBF24)),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isConnected ? 1.5 : 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── In-Call Keypad (DTMF 1, 2, 3...) ───────────────────────────────────────
  Widget _buildInCallKeypad(CallViewModel vm) {
    final keys = [
      ['1', ''],
      ['2', 'ABC'],
      ['3', 'DEF'],
      ['4', 'GHI'],
      ['5', 'JKL'],
      ['6', 'MNO'],
      ['7', 'PQRS'],
      ['8', 'TUV'],
      ['9', 'WXYZ'],
      ['*', ''],
      ['0', '+'],
      ['#', ''],
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Spacer(),
        // Display Digits / Header
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          alignment: Alignment.center,
          child: Text(
            vm.dtmfDigits.isEmpty ? 'Touch Tone Keypad' : vm.dtmfDigits,
            style: TextStyle(
              color: vm.dtmfDigits.isEmpty ? const Color(0xFF64748B) : Colors.white,
              fontSize: vm.dtmfDigits.isEmpty ? 16 : 28,
              fontWeight: FontWeight.w700,
              letterSpacing: vm.dtmfDigits.isEmpty ? 0.5 : 3.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Keypad Grid aligned down in the easy thumb reach zone
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.35,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final key = keys[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    vm.appendDtmf(key[0]);
                  },
                  borderRadius: BorderRadius.circular(18),
                  splashColor: const Color(0xFF38BDF8).withAlpha(60),
                  highlightColor: const Color(0xFF38BDF8).withAlpha(30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withAlpha(220),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF334155), width: 1.2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          key[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (key[1].isNotEmpty)
                          Text(
                            key[1],
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Helper Control Button ───────────────────────────────────────────────────
  Widget _buildInCallControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isActive ? activeColor.withAlpha(50) : const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? activeColor : const Color(0xFF334155),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withAlpha(100),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? activeColor : const Color(0xFFE2E8F0),
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _safeInitials(String fullName) {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'L';
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      final w1 = words[0].characters.firstOrNull;
      final w2 = words[1].characters.firstOrNull;
      if (w1 != null && w2 != null) {
        return '$w1$w2'.toUpperCase();
      }
    }
    return clean.characters.first.toUpperCase();
  }
}
