import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shows a custom, pixel-perfect 12-Hour Clock Picker with AM/PM toggle
/// completely immune to Android ROM 24-hour double-ring distortion.
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String helpText = 'SELECT TIME',
  Color? primaryColor,
  TimePickerEntryMode initialEntryMode = TimePickerEntryMode.dial,
}) async {
  return await showDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AppTimePickerDialog(
      initialTime: initialTime,
      helpText: helpText,
      primaryColor: primaryColor ?? AppColors.ssGoldDark,
    ),
  );
}

/// Custom 12-Hour Luxury Clock Dialog
class _AppTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String helpText;
  final Color primaryColor;

  const _AppTimePickerDialog({
    required this.initialTime,
    required this.helpText,
    required this.primaryColor,
  });

  @override
  State<_AppTimePickerDialog> createState() => _AppTimePickerDialogState();
}

class _AppTimePickerDialogState extends State<_AppTimePickerDialog> {
  late int _selectedHour; // 1..12
  late int _selectedMinute; // 0..59
  late DayPeriod _selectedPeriod; // am / pm
  bool _isPickingHour = true; // true = hour, false = minute

  @override
  void initState() {
    super.initState();
    final hour24 = widget.initialTime.hour;
    _selectedPeriod = hour24 >= 12 ? DayPeriod.pm : DayPeriod.am;
    _selectedHour = hour24 % 12;
    if (_selectedHour == 0) _selectedHour = 12;
    _selectedMinute = widget.initialTime.minute;
  }

  void _onQuickPreset(int hour12, int minute, DayPeriod period) {
    setState(() {
      _selectedHour = hour12;
      _selectedMinute = minute;
      _selectedPeriod = period;
    });
  }

  void _confirm() {
    int hour24 = _selectedHour % 12;
    if (_selectedPeriod == DayPeriod.pm) {
      hour24 += 12;
    }
    Navigator.of(context).pop(TimeOfDay(hour: hour24, minute: _selectedMinute));
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = widget.primaryColor;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Help Text / Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.helpText.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: brandColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '12-Hour Clock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: brandColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Big 12-Hour Digits Header + AM/PM Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour Box
                  _buildTimeBox(
                    text: _selectedHour.toString().padLeft(2, '0'),
                    isSelected: _isPickingHour,
                    onTap: () => setState(() => _isPickingHour = true),
                    brandColor: brandColor,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),

                  // Minute Box
                  _buildTimeBox(
                    text: _selectedMinute.toString().padLeft(2, '0'),
                    isSelected: !_isPickingHour,
                    onTap: () => setState(() => _isPickingHour = false),
                    brandColor: brandColor,
                  ),

                  const SizedBox(width: 14),

                  // AM / PM Segmented Control
                  _buildAmPmToggle(brandColor),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Quick Preset Pills (e.g., Morning, Noon, Evening)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('10:30 AM', 10, 30, DayPeriod.am, brandColor),
                    const SizedBox(width: 6),
                    _buildPresetChip('12:00 PM', 12, 0, DayPeriod.pm, brandColor),
                    const SizedBox(width: 6),
                    _buildPresetChip('03:30 PM', 3, 30, DayPeriod.pm, brandColor),
                    const SizedBox(width: 6),
                    _buildPresetChip('05:00 PM', 5, 0, DayPeriod.pm, brandColor),
                    const SizedBox(width: 6),
                    _buildPresetChip('06:30 PM', 6, 30, DayPeriod.pm, brandColor),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Single-Ring Luxury Clock Face (12-Hour Single Ring)
              _buildClockFace(brandColor),

              const SizedBox(height: 18),

              // 5. Actions: Cancel & OK
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      'Confirm Time',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required Color brandColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3E2723) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? brandColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3E2723).withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isSelected ? const Color(0xFFEDD98A) : const Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmPmToggle(Color brandColor) {
    final isAm = _selectedPeriod == DayPeriod.am;

    return Container(
      width: 58,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // AM
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = DayPeriod.am),
              child: Container(
                decoration: BoxDecoration(
                  color: isAm ? brandColor : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Center(
                  child: Text(
                    'AM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isAm ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          // PM
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = DayPeriod.pm),
              child: Container(
                decoration: BoxDecoration(
                  color: !isAm ? brandColor : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                ),
                child: Center(
                  child: Text(
                    'PM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: !isAm ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    int hour12,
    int minute,
    DayPeriod period,
    Color brandColor,
  ) {
    final isSelected = _selectedHour == hour12 &&
        _selectedMinute == minute &&
        _selectedPeriod == period;

    return GestureDetector(
      onTap: () => _onQuickPreset(hour12, minute, period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? brandColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? brandColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ── Single-Ring Clean Clock Face ─────────────────────────────────────────
  Widget _buildClockFace(Color brandColor) {
    const double dialSize = 220;
    final List<int> values = _isPickingHour
        ? [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        : [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

    final int currentValue = _isPickingHour ? _selectedHour : _selectedMinute;

    return Container(
      width: dialSize,
      height: dialSize,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Pin
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: brandColor,
              shape: BoxShape.circle,
            ),
          ),

          // Hand Pointer Line & Selector Ball
          CustomPaint(
            size: const Size(dialSize, dialSize),
            painter: _ClockHandPainter(
              value: currentValue,
              isHour: _isPickingHour,
              color: brandColor,
            ),
          ),

          // Numbers placed cleanly in a single spacious circle (radius ~ 82)
          ...List.generate(12, (index) {
            final val = values[index];
            // 12 is at -90 deg (top)
            final double angle = (index * 30 - 90) * (math.pi / 180);
            const double radius = 80;
            final double x = radius * math.cos(angle);
            final double y = radius * math.sin(angle);

            final bool isSelected = _isPickingHour
                ? (_selectedHour == val)
                : (_selectedMinute == val || (_selectedMinute ~/ 5 * 5 == val && _selectedMinute % 5 == 0));

            return Transform.translate(
              offset: Offset(x, y),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isPickingHour) {
                      _selectedHour = val;
                      _isPickingHour = false; // Auto switch to minute!
                    } else {
                      _selectedMinute = val;
                    }
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? brandColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _isPickingHour ? '$val' : val.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ClockHandPainter extends CustomPainter {
  final int value;
  final bool isHour;
  final Color color;

  _ClockHandPainter({
    required this.value,
    required this.isHour,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double angle = isHour
        ? ((value % 12) * 30 - 90) * (math.pi / 180)
        : (value * 6 - 90) * (math.pi / 180);

    const double radius = 80;
    final target = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    // Draw Hand Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, target, linePaint);

    // Draw Selected End Circle
    final ballPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(target, 16, ballPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockHandPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.isHour != isHour ||
        oldDelegate.color != color;
  }
}

/// Robust Date Picker
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String helpText = 'SELECT DATE',
  Color? primaryColor,
}) async {
  final brandColor = primaryColor ?? AppColors.ssGoldDark;

  return await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    builder: (BuildContext ctx, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(ctx).copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: brandColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              elevation: 8,
              headerBackgroundColor: brandColor,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              headerHeadlineStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              confirmButtonStyle: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child ?? const SizedBox(),
        ),
      );
    },
  );
}
