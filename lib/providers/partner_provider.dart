import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/mood_entry.dart';
import '../models/partner_info.dart';
import '../core/services/partner_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/notification_service.dart';
import 'auth_provider.dart';
import 'mood_provider.dart';


class PartnerState {
  final PartnerInfo? partnerInfo;
  final Map<String, MoodEntry> partnerEntries;
  final String? generatedCode;
  final bool isLoading;
  final String? errorMessage;

  const PartnerState({
    this.partnerInfo,
    this.partnerEntries = const {},
    this.generatedCode,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isPaired => partnerInfo != null;

  PartnerState copyWith({
    PartnerInfo? partnerInfo,
    bool clearPartner = false,
    Map<String, MoodEntry>? partnerEntries,
    String? generatedCode,
    bool clearGeneratedCode = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PartnerState(
      partnerInfo: clearPartner ? null : (partnerInfo ?? this.partnerInfo),
      partnerEntries: partnerEntries ?? this.partnerEntries,
      generatedCode: clearGeneratedCode ? null : (generatedCode ?? this.generatedCode),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PartnerNotifier extends StateNotifier<PartnerState> {
  final PartnerService _partnerService;
  final StorageService _storageService;
  StreamSubscription<Map<String, MoodEntry>>? _entriesSubscription;
  StreamSubscription<PartnerInfo?>? _partnerInfoSubscription;

  PartnerNotifier(this._partnerService, this._storageService)
      : super(const PartnerState()) {
    _loadInitialState();
  }

  void _loadInitialState() {
    final localPartner = _storageService.getSavedPartner();
    final localEntries = _storageService.getPartnerEntries();
    state = state.copyWith(
      partnerInfo: localPartner,
      partnerEntries: localEntries,
    );
  }

  Future<void> syncWithCloudUser(AppUser? currentUser) async {
    if (currentUser == null) {
      _partnerInfoSubscription?.cancel();
      _entriesSubscription?.cancel();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // Subscribe to real-time partner link updates on user document
    _partnerInfoSubscription?.cancel();
    _partnerInfoSubscription =
        _partnerService.streamUserPartnerInfo(currentUser.id).listen(
      (cloudPartner) {
        state = state.copyWith(
          partnerInfo: cloudPartner,
          clearPartner: cloudPartner == null,
          isLoading: false,
          clearGeneratedCode: cloudPartner != null,
        );

        if (cloudPartner != null) {
          _subscribeToPartnerEntries(cloudPartner.uid);
        } else {
          _entriesSubscription?.cancel();
          state = state.copyWith(partnerEntries: {});
        }
      },
      onError: (err) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to stream partner info',
        );
      },
    );
  }

  void _subscribeToPartnerEntries(String partnerUid) {
    _entriesSubscription?.cancel();
    bool isFirstSnapshot = true;

    _entriesSubscription = _partnerService.streamPartnerEntries(partnerUid).listen(
      (entries) {
        if (!isFirstSnapshot) {
          final oldEntries = state.partnerEntries;
          for (final mapEntry in entries.entries) {
            final dateKey = mapEntry.key;
            final newMood = mapEntry.value;
            final oldMood = oldEntries[dateKey];

            if (oldMood == null ||
                oldMood.emoji != newMood.emoji ||
                oldMood.note != newMood.note) {
              final partnerName = state.partnerInfo?.displayName ?? 'Your FT';
              NotificationService().showPartnerMoodNotification(
                partnerName: partnerName,
                emoji: newMood.emoji,
                note: newMood.note,
                date: newMood.date,
              );
              break;
            }
          }
        }
        isFirstSnapshot = false;
        state = state.copyWith(partnerEntries: entries);
      },
      onError: (err) {
        state = state.copyWith(errorMessage: 'Partner stream error');
      },
    );
  }



  Future<String?> generateCode(AppUser currentUser) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final code = await _partnerService.generatePairingCode(currentUser);
      state = state.copyWith(generatedCode: code, isLoading: false);
      return code;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> redeemCode(String code, AppUser currentUser) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final partner = await _partnerService.redeemPairingCode(
        code: code,
        currentUser: currentUser,
      );
      state = state.copyWith(
        partnerInfo: partner,
        isLoading: false,
        clearGeneratedCode: true,
      );
      _subscribeToPartnerEntries(partner.uid);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> unpair(AppUser? currentUser) async {
    state = state.copyWith(isLoading: true);
    final partnerUid = state.partnerInfo?.uid ?? '';
    await _partnerService.unpairPartner(currentUser?.id ?? '', partnerUid);
    _entriesSubscription?.cancel();
    state = const PartnerState();
  }

  MoodEntry? getPartnerEntryForDate(DateTime date) {
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return state.partnerEntries[dateKey];
  }

  @override
  void dispose() {
    _partnerInfoSubscription?.cancel();
    _entriesSubscription?.cancel();
    super.dispose();
  }

}

final partnerProvider = StateNotifierProvider<PartnerNotifier, PartnerState>((ref) {
  final partnerService = ref.watch(partnerServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final notifier = PartnerNotifier(partnerService, storageService);

  // Sync partner status whenever auth changes
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.user != null) {
      notifier.syncWithCloudUser(next.user);
    }
  });

  return notifier;
});
