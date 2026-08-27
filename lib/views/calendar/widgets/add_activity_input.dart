import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// An inline input field for quickly adding new activities.
/// Includes a button to pull a random idea and a text field for custom plans.
class AddActivityInput extends StatelessWidget {
  /// The currently selected day
  final DateTime selectedDay;

  /// The controller for the text input
  final TextEditingController controller;

  /// The focus node for the text input
  final FocusNode focusNode;

  /// Callback when the post button or enter is pressed
  final VoidCallback onSubmit;

  /// Callback when the random idea button is tapped
  final VoidCallback onRandomIdeaTap;

  const AddActivityInput({
    super.key,
    required this.selectedDay,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onRandomIdeaTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onRandomIdeaTap,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text("🎲", style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "Add an idea or plan for ${DateFormat('EEEE').format(selectedDay)}...",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }
}
