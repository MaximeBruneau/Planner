class EmojiPack {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String price;
  final bool isFree;
  final List<String> emojis;

  const EmojiPack({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.price = '\$0.99',
    this.isFree = false,
    required this.emojis,
  });
}

class EmojiPacks {
  static const String defaultPackId = 'default_pack';

  static const defaultEmojis = [
    '😄',
    '😴',
    '🥺',
    '🤯',
    '😡',
    '🥳',
    '💪',
    '💼',
    '🎮',
    '💆‍♂️',
    '✈️',
    '🤒',
    '🥵',
    '🍕',
    '🥰',
    '🍆',
    '❤️',
    '☕',
    '🌧️',
    '✨',
  ];

  static const List<EmojiPack> list = [
    EmojiPack(
      id: defaultPackId,
      name: 'Starter Essentials',
      emoji: '🌸',
      description: 'The 20 essential starter vibes, free forever.',
      price: 'Free',
      isFree: true,
      emojis: defaultEmojis,
    ),

    EmojiPack(
      id: 'cute_animals',
      name: 'Cute Animals',
      emoji: '🐱',
      description: '10 adorably expressive animal companions.',
      price: '\$0.99',
      emojis: [
        '🐱',
        '🐶',
        '🐰',
        '🐼',
        '🦊',
        '🐻',
        '🐨',
        '🦁',
        '🐸',
        '🦄',
      ],
    ),
    EmojiPack(
      id: 'food_treats',
      name: 'Food & Treats',
      emoji: '🍩',
      description: '10 delicious food, coffee & sweet treats.',
      price: '\$0.99',
      emojis: [
        '🍕',
        '🍔',
        '🍣',
        '🍩',
        '🍦',
        '🍓',
        '🥑',
        '🥞',
        '🥐',
        '🧁',
      ],
    ),
    EmojiPack(
      id: 'vibes_moods',
      name: 'Vibes & Moods',
      emoji: '🌈',
      description: '10 deep expressive emotional vibe faces.',
      price: '\$0.99',
      emojis: [
        '🥳',
        '😎',
        '🥹',
        '🤩',
        '🫠',
        '😴',
        '🤔',
        '🥰',
        '🤪',
        '😇',
      ],
    ),
    EmojiPack(
      id: 'nature_chill',
      name: 'Nature & Chill',
      emoji: '🌿',
      description: '10 peaceful celestial & outdoor nature icons.',
      price: '\$0.99',
      emojis: [
        '🌸',
        '🌺',
        '🌻',
        '🌲',
        '🍁',
        '🌙',
        '⭐',
        '🌊',
        '⚡',
        '🌈',
      ],
    ),
    EmojiPack(
      id: 'gaming_geek',
      name: 'Gaming & Geek',
      emoji: '🎮',
      description: '10 arcade, space & retro gamer emojis.',
      price: '\$0.99',
      emojis: [
        '🎮',
        '👾',
        '🕹️',
        '🎲',
        '🚀',
        '🔮',
        '🎧',
        '⚡',
        '🤖',
        '🏆',
      ],
    ),
    EmojiPack(
      id: 'duo_love',
      name: 'Duo & Love',
      emoji: '🐰',
      description: '10 romantic & best friend duo emojis for your Partner.',
      price: '\$0.99',
      emojis: [
        '💖',
        '💕',
        '💞',
        '💌',
        '🐰',
        '🐻',
        '💍',
        '💐',
        '🍓',
        '🥂',
      ],
    ),
    EmojiPack(
      id: 'christmas_magic',
      name: 'Christmas Magic',
      emoji: '🎄',
      description: '10 festive holiday & winter Christmas vibes.',
      price: '\$0.99',
      emojis: [
        '🎄',
        '🎅',
        '⛄',
        '🎁',
        '❄️',
        '🦌',
        '🔔',
        '🍪',
        '🕯️',
        '🥂',
      ],
    ),
  ];

  static List<String> get paidPackIds =>
      list.where((p) => !p.isFree).map((p) => p.id).toList();

  static EmojiPack getById(String id) {
    return list.firstWhere(
      (p) => p.id == id,
      orElse: () => list.first,
    );
  }

  static EmojiPack? getPackForEmoji(String emoji) {
    for (final pack in list) {
      if (pack.emojis.contains(emoji)) {
        return pack;
      }
    }
    return null;
  }
}
