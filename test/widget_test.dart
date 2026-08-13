import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_dairy/main.dart';
import 'package:my_dairy/core/services/storage_service.dart';
import 'package:my_dairy/providers/mood_provider.dart';

void main() {
  testWidgets('App renders main calendar screen title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const VibeCalendarApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main screen renders title containing "My Everyday Vibe"
    expect(find.textContaining('My Everyday Vibe'), findsOneWidget);
  });
}
