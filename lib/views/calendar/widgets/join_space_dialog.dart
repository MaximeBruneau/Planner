import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/space_provider.dart';

/// A dialog that allows a user to join an existing space using a code.
class JoinSpaceDialog extends ConsumerStatefulWidget {
  const JoinSpaceDialog({super.key});

  /// Displays the dialog.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => const JoinSpaceDialog(),
    );
  }

  @override
  ConsumerState<JoinSpaceDialog> createState() => _JoinSpaceDialogState();
}

class _JoinSpaceDialogState extends ConsumerState<JoinSpaceDialog> {
  final _joinCodeController = TextEditingController();
  bool _isSubmitting = false;
  String? _localError;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Text("🔗", style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            "Join Calendar",
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Enter the invite code (e.g. SUPER-4892) shared by your group.",
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _joinCodeController,
            textCapitalization: TextCapitalization.characters,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              labelText: "Invite Code",
              hintText: "SUPER-1234",
              prefixIcon: const Icon(Icons.vpn_key_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (_localError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localError!,
                      style: TextStyle(color: colorScheme.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  final code = _joinCodeController.text.trim();
                  if (code.isEmpty) return;

                  setState(() {
                    _isSubmitting = true;
                    _localError = null;
                  });

                  final navigator = Navigator.of(context);
                  final success = await ref.read(spaceProvider.notifier).joinSpace(code);

                  if (!mounted) return;

                  if (success) {
                    navigator.pop(code);
                  } else {
                    final err = ref.read(spaceProvider).errorMessage ?? "Could not join space.";
                    setState(() {
                      _isSubmitting = false;
                      _localError = err;
                    });
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Join Space"),
        ),
      ],
    );
  }
}
