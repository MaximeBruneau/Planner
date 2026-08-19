import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/iap_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/streak_service.dart';
import '../models/mood_entry.dart';
import 'auth_provider.dart';
import 'mood_provider.dart';
import 'partner_provider.dart';

class StreakState {
  final int personalStreak;
  final int duoFlames;
  final double flameProgress; // 0.0 to 1.0 towards 50
  final bool isMilestone50Claimed;
  final bool isLegendaryFlame;
  final String? lastUnlockedThemeId;

  const StreakState({
    this.personalStreak = 0,
    this.duoFlames = 0,
    this.flameProgress = 0.0,
    this.isMilestone50Claimed = false,
    this.isLegendaryFlame = false,
    this.lastUnlockedThemeId,
  });

  bool get canClaim50Milestone => duoFlames >= 50 && !isMilestone50Claimed;

  StreakState copyWith({
    int? personalStreak,
    int? duoFlames,
    double? flameProgress,
    bool? isMilestone50Claimed,
    bool? isLegendaryFlame,
    String? lastUnlockedThemeId,
  }) {
    return StreakState(
      personalStreak: personalStreak ?? this.personalStreak,
      duoFlames: duoFlames ?? this.duoFlames,
      flameProgress: flameProgress ?? this.flameProgress,
      isMilestone50Claimed: isMilestone50Claimed ?? this.isMilestone50Claimed,
      isLegendaryFlame: isLegendaryFlame ?? this.isLegendaryFlame,
      lastUnlockedThemeId: lastUnlockedThemeId ?? this.lastUnlockedThemeId,
    );
  }
}

class StreakNotifier extends StateNotifier<StreakState> {
  final StorageService _storageService;
  final IapService _iapService;

  StreakNotifier(this._storageService, this._iapService)
      : super(const StreakState());

  void recalculate({
    required Map<String, MoodEntry> userEntries,
    required Map<String, MoodEntry> partnerEntries,
  }) {
    final settings = _storageService.getSettings();
    final personal = StreakService.calculatePersonalStreak(userEntries);
    final duo = StreakService.calculateDuoFlames(userEntries, partnerEntries);
    final progress = (duo / 50.0).clamp(0.0, 1.0);
    final isClaimed = settings.claimedFlameMilestones['50'] == true;

    state = state.copyWith(
      personalStreak: personal,
      duoFlames: duo,
      flameProgress: progress,
      isMilestone50Claimed: isClaimed,
    );
  }

  /// Automatically attempt to claim the 50 flame milestone if available
  Future<String?> checkAndClaimMilestone({String? userId}) async {
    if (state.duoFlames < 50) return null;
    final settings = _storageService.getSettings();
    if (settings.claimedFlameMilestones['50'] == true) return null;

    final unlockedThemeId = await _iapService.claim50FlameMilestone(
      duoFlames: state.duoFlames,
      userId: userId,
    );

    if (unlockedThemeId != null) {
      final isLegendary = unlockedThemeId == 'all_unlocked';
      state = state.copyWith(
        isMilestone50Claimed: true,
        isLegendaryFlame: isLegendary,
        lastUnlockedThemeId: unlockedThemeId,
      );
    }
    return unlockedThemeId;
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final iapService = ref.watch(iapServiceProvider);
  final notifier = StreakNotifier(storageService, iapService);


  // Watch moods & partner entries to update streaks reactively
  final userMoods = ref.watch(moodProvider);
  final partnerState = ref.watch(partnerProvider);
  final authState = ref.watch(authProvider);

  notifier.recalculate(
    userEntries: userMoods,
    partnerEntries: partnerState.partnerEntries,
  );

  // Auto-check 50 flame milestone
  if (partnerState.isPaired) {
    notifier.checkAndClaimMilestone(userId: authState.user?.id);
  }

  return notifier;
});
