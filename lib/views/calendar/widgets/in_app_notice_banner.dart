import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated banner for in-app real-time notifications with auto-dismiss and close actions.
class InAppNoticeBanner extends StatelessWidget {
  final String? notice;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const InAppNoticeBanner({
    super.key,
    required this.notice,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: notice == null
          ? const SizedBox.shrink()
          : Material(
              key: ValueKey(notice),
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text("🔔", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notice!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
