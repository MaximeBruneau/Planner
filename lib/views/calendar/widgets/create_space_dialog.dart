import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/space_provider.dart';

/// A dialog that allows a user to create a new shared space.
class CreateSpaceDialog extends ConsumerStatefulWidget {
  const CreateSpaceDialog({super.key});

  /// Displays the dialog.
  static Future<Map<String, String>?> show(BuildContext context) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const CreateSpaceDialog(),
    );
  }

  @override
  ConsumerState<CreateSpaceDialog> createState() => _CreateSpaceDialogState();
}

class _CreateSpaceDialogState extends ConsumerState<CreateSpaceDialog> {
  final _createNameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _createNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Text("✨", style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            "New Shared Calendar",
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Give your shared calendar space a name (e.g. Weekend Squad 🍕, Paris Trip ✈️, Family 🏡)",
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _createNameController,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              labelText: "Space Name",
              hintText: "e.g. Weekend Squad 🍕",
              prefixIcon: const Icon(Icons.group_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
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
                  final name = _createNameController.text.trim();
                  setState(() => _isSubmitting = true);

                  final navigator = Navigator.of(context);
                  final space = await ref.read(spaceProvider.notifier).createSpace(
                        name: name.isNotEmpty ? name : 'Our Shared Calendar 🗓️',
                      );
                  
                  if (!mounted) return;

                  if (space != null) {
                    navigator.pop({'name': space.name, 'code': space.code});
                  } else {
                    setState(() => _isSubmitting = false);
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Create Space"),
        ),
      ],
    );
  }
}
