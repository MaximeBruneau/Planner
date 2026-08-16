import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/mood_entry.dart';
import '../models/partner_info.dart';
import '../core/services/partner_service.dart';
import '../core/services/storage_service.dart';
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
    if (currentUser == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cloudPartner = await _partnerService.fetchCloudPartner(currentUser.id);
      state = state.copyWith(
        partnerInfo: cloudPartner,
        clearPartner: cloudPartner == null,
        isLoading: false,
      );

      if (cloudPartner != null) {
        _subscribeToPartnerEntries(cloudPartner.uid);
      } else {
        _entriesSubscription?.cancel();
        state = state.copyWith(partnerEntries: {});
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to sync partner info',
      );
    }
  }

  void _subscribeToPartnerEntries(String partnerUid) {
    _entriesSubscription?.cancel();
    _entriesSubscription = _partnerService.streamPartnerEntries(partnerUid).listen(
      (entries) {
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
