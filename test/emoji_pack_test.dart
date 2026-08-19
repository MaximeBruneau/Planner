import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_dairy/models/emoji_pack.dart';
import 'package:my_dairy/models/app_settings.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('EmojiPack & Store Tests', () {
    test('Default starter essentials pack is free and has 20 emojis', () {
      final defaultPack = EmojiPacks.getById(EmojiPacks.defaultPackId);
      expect(defaultPack.isFree, isTrue);
      expect(defaultPack.emojis.length, equals(20));
      expect(defaultPack.emojis, contains('✨'));
      expect(defaultPack.emojis, contains('😄'));
    });

    test('There are 7 official emoji packs (starter has 20, paid packs have 10)', () {
      expect(EmojiPacks.list.length, equals(7));
      for (final pack in EmojiPacks.list) {
        expect(pack.emojis.length >= 10, isTrue);
        expect(pack.name.isNotEmpty, isTrue);
      }
    });

    test('Paid pack IDs list contains all 6 non-free packs', () {
      final paidIds = EmojiPacks.paidPackIds;
      expect(paidIds.length, equals(6));
      expect(paidIds, contains('cute_animals'));
      expect(paidIds, contains('food_treats'));
      expect(paidIds, contains('vibes_moods'));
      expect(paidIds, contains('nature_chill'));
      expect(paidIds, contains('gaming_geek'));
      expect(paidIds, contains('duo_love'));
    });

    test('getPackForEmoji finds corresponding pack for an emoji', () {
      final catPack = EmojiPacks.getPackForEmoji('🐱');
      expect(catPack, isNotNull);
      expect(catPack!.id, equals('cute_animals'));

      final sushiPack = EmojiPacks.getPackForEmoji('🍣');
      expect(sushiPack, isNotNull);
      expect(sushiPack!.id, equals('food_treats'));
    });


    test('AppSettings handles unlocked emoji packs properly', () {
      final settings = AppSettings();
      expect(settings.isEmojiPackUnlocked(EmojiPacks.defaultPackId), isTrue);
      expect(settings.isEmojiPackUnlocked('cute_animals'), isFalse);

      final updated = settings.copyWith(
        unlockedEmojiPacks: [EmojiPacks.defaultPackId, 'cute_animals'],
      );
      expect(updated.isEmojiPackUnlocked('cute_animals'), isTrue);
      expect(updated.isEmojiUnlocked('🐱'), isTrue);
    });

    test('AppSettings JSON serialization preserves unlockedEmojiPacks', () {
      final settings = AppSettings(
        unlockedEmojiPacks: [EmojiPacks.defaultPackId, 'food_treats'],
      );
      final jsonStr = settings.toJson();
      final decoded = AppSettings.fromJson(jsonStr);

      expect(decoded.unlockedEmojiPacks, contains('food_treats'));
      expect(decoded.isEmojiPackUnlocked('food_treats'), isTrue);
    });
  });
}
