import 'package:flutter/material.dart';

/// Round button that arms "place Lollipop" mode; the next tap on the field
/// then drops the decoy there. Disabled while one is already active, since
/// only a single Lollipop decoy can exist at a time.
class LollipopButton extends StatelessWidget {
  const LollipopButton({
    super.key,
    required this.enabled,
    required this.armed,
    required this.onPressed,
  });

  final bool enabled;
  final bool armed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: armed
                ? const Color(0xFFDB2777).withValues(alpha: 0.85)
                : Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: armed
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.25),
              width: armed ? 2 : 1,
            ),
            boxShadow: armed
                ? [
                    BoxShadow(
                      color: const Color(0xFFDB2777).withValues(alpha: 0.55),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/lollipop_100.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
