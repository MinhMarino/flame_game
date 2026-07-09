import 'package:flutter/material.dart';

/// Round toggle floating on the right-middle of the gameplay screen that
/// lets the player switch between plain taps and the animated fly-swatter
/// cursor in Endless mode.
class SwatterToggleButton extends StatelessWidget {
  const SwatterToggleButton({
    super.key,
    required this.enabled,
    required this.active,
    required this.onPressed,
  });

  final bool enabled;
  final bool active;
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
            color: active
                ? const Color(0xFF2563EB).withValues(alpha: 0.85)
                : Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.25),
              width: active ? 2 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.55),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Image.asset(
                'assets/images/fly_swatter.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
