import 'package:flutter_test/flutter_test.dart';
import 'package:my_dairy/core/services/purchases_service.dart';
import 'package:my_dairy/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late PurchasesService purchasesService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    purchasesService = PurchasesService(storageService);
  });

  group('PurchasesService & RevenueCat Subscriptions Tests', () {
    test('Default user is not premium and has no duo pass', () {
      final settings = storageService.getSettings();
      expect(settings.isPremium, isFalse);
      expect(settings.isDuoPass, isFalse);
      expect(settings.hasActivePremium, isFalse);
    });

    test('purchaseSubscription Monthly grants premium for 30 days', () async {
      final success = await purchasesService.purchaseSubscription(
        tier: SubscriptionTier.monthly,
      );

      expect(success, isTrue);
      final settings = storageService.getSettings();
      expect(settings.isPremium, isTrue);
      expect(settings.isDuoPass, isFalse);
      expect(settings.hasActivePremium, isTrue);
      expect(settings.isThemeUnlocked('starry_night'), isTrue);
      expect(settings.isEmojiPackUnlocked('cute_animals'), isTrue);
    });

    test('purchaseSubscription DuoPass activates Duo Pass entitlement', () async {
      final success = await purchasesService.purchaseSubscription(
        tier: SubscriptionTier.duoPass,
      );

      expect(success, isTrue);
      final settings = storageService.getSettings();
      expect(settings.isPremium, isTrue);
      expect(settings.isDuoPass, isTrue);
      expect(settings.hasActivePremium, isTrue);
    });

    test('purchaseSingleTheme unlocks individual theme permanently', () async {
      final success = await purchasesService.purchaseSingleTheme(
        themeId: 'starry_night',
      );

      expect(success, isTrue);
      final settings = storageService.getSettings();
      expect(settings.isThemeUnlocked('starry_night'), isTrue);
      expect(settings.isThemeUnlocked('neon_cyberpunk'), isFalse);
    });

    test('purchaseSingleEmojiPack unlocks individual pack', () async {
      final success = await purchasesService.purchaseSingleEmojiPack(
        packId: 'cute_animals',
      );

      expect(success, isTrue);
      final settings = storageService.getSettings();
      expect(settings.isEmojiPackUnlocked('cute_animals'), isTrue);
      expect(settings.isEmojiPackUnlocked('food_treats'), isFalse);
    });

    test('restorePurchases restores previous state and returns map', () async {
      await purchasesService.purchaseSingleTheme(themeId: 'neon_cyberpunk');
      await purchasesService.purchaseSubscription(tier: SubscriptionTier.monthly);

      final result = await purchasesService.restorePurchases();
      expect(result['isPremium'], isTrue);
      expect(result['themes'], contains('neon_cyberpunk'));
    });
  });
}
