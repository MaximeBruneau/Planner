import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mood_provider.dart';
import 'purchases_service.dart';
import 'storage_service.dart';
import 'streak_service.dart';



class IapService {
  final StorageService _storageService;
  final PurchasesService _purchasesService;

  IapService(this._storageService, this._purchasesService);

  /// Purchase a single theme by ID (1,99 €)
  Future<bool> purchaseTheme({
    required String themeId,
    String? userId,
  }) async {
    return _purchasesService.purchaseSingleTheme(
      themeId: themeId,
      userId: userId,
    );
  }

  /// Purchase "All Themes Pack" (3,99 €)
  Future<bool> purchaseAllThemesPack({String? userId}) async {
    return _purchasesService.purchaseAllThemesPack(userId: userId);
  }

  /// Purchase a single emoji pack by ID (0,99 €)
  Future<bool> purchaseEmojiPack({
    required String packId,
    String? userId,
  }) async {
    return _purchasesService.purchaseSingleEmojiPack(
      packId: packId,
      userId: userId,
    );
  }

  /// Purchase "All Emoji Packs" master bundle (2,99 €)
  Future<bool> purchaseAllEmojiPacks({String? userId}) async {
    return _purchasesService.purchaseAllEmojiPacks(userId: userId);
  }

  /// Purchase Premium Subscription (Monthly, Yearly with Trial, or Duo Pass)
  Future<bool> purchaseSubscription({
    required SubscriptionTier tier,
    String? userId,
    String? partnerId,
  }) async {
    return _purchasesService.purchaseSubscription(
      tier: tier,
      userId: userId,
      partnerId: partnerId,
    );
  }

  /// Restore purchases
  Future<Map<String, dynamic>> restorePurchases({
    String? userId,
    String? partnerId,
  }) async {
    return _purchasesService.restorePurchases(
      userId: userId,
      partnerId: partnerId,
    );
  }
  /// Claim random theme unlock on reaching 50 duo flames
  Future<String?> claim50FlameMilestone({
    required int duoFlames,
    String? userId,
  }) async {
    final settings = _storageService.getSettings();
    final unlockedThemes = settings.unlockedThemes;
    final claimedMilestones = settings.claimedFlameMilestones;

    final result = StreakService.checkAndClaim50FlameMilestone(
      duoFlames: duoFlames,
      currentUnlockedThemes: unlockedThemes,
      claimedMilestones: claimedMilestones,
    );

    if (result == null) return null;

    final updatedMilestones = Map<String, bool>.from(claimedMilestones)..['50'] = true;
    List<String> updatedThemes = List<String>.from(unlockedThemes);

    if (result != 'all_unlocked') {
      if (!updatedThemes.contains(result)) {
        updatedThemes.add(result);
      }
    }

    final updatedSettings = settings.copyWith(
      unlockedThemes: updatedThemes,
      claimedFlameMilestones: updatedMilestones,
    );
    await _storageService.saveSettings(updatedSettings);

    return result;
  }
}

final iapServiceProvider = Provider<IapService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final purchasesService = ref.watch(purchasesServiceProvider);
  return IapService(storageService, purchasesService);
});
