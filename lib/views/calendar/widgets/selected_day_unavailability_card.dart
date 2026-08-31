import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/day_unavailability.dart';

/// Card displayed above the day's activity list showing unavailable members and a quick toggle.
class SelectedDayUnavailabilityCard extends StatelessWidget {
  final DateTime selectedDay;
  final List<DayUnavailability> unavailabilities;
  final bool isCurrentUserUnavailable;
  final VoidCallback onToggleAvailability;

  const SelectedDayUnavailabilityCard({
    super.key,
    required this.selectedDay,
    required this.unavailabilities,
    required this.isCurrentUserUnavailable,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUnavailabilities = unavailabilities.isNotEmpty;

    const redColor = Color(0xFFE53935);
    const darkRedColor = Color(0xFFC62828);

    if (hasUnavailabilities) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: redColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: redColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: redColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: redColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Not available (${unavailabilities.length})",
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkRedColor,
                    ),
                  ),
                ),
                _buildToggleButton(context),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: unavailabilities.map((u) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: redColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: redColor.withValues(alpha: 0.15),
                        backgroundImage: u.userPhotoUrl != null && u.userPhotoUrl!.isNotEmpty
                            ? NetworkImage(u.userPhotoUrl!)
                            : null,
                        child: u.userPhotoUrl == null || u.userPhotoUrl!.isEmpty
                            ? Text(
                                u.userName.isNotEmpty ? u.userName[0].toUpperCase() : "👤",
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: darkRedColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        u.userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    // When everyone is available
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Everyone is available",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          _buildToggleButton(context),
        ],
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    const redColor = Color(0xFFE53935);

    if (isCurrentUserUnavailable) {
      return OutlinedButton.icon(
        onPressed: onToggleAvailability,
        icon: const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
        label: const Text(
          "I'm Available ✅",
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          side: BorderSide(color: Colors.green.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onToggleAvailability,
      icon: const Icon(Icons.block_rounded, size: 14, color: redColor),
      label: const Text(
        "I'm not available 🚫",
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: redColor),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        side: BorderSide(color: redColor.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
