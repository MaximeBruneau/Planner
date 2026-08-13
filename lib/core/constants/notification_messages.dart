import 'dart:math';

class NotificationMessages {
  static const List<String> messages = [
    "How was your day today? Don't forget to drop your emoji! 🌸",
    "Time for a quick daily check-in! How are you feeling? 🌙",
    "A quick moment for yourself: How did today go? ✨",
    "Tell your calendar about your day! 📝",
    "Wrapping up your day? Add today's mood emoji! 🥑",
    "Your daily mood check-in is waiting for you! 💫",
    "How was today on a scale of emojis? Let us know! 😊",
    "Take a deep breath and log today's vibe! 🌿",
    "A cozy reminder to record your day's story! 📖",
    "Don't break the streak! How was today? 🔥",
    "Nighty night! Don't forget to save today's mood! 😴",
    "One little emoji to sum up your day! 🎈",
    "Hope today brought you good vibes! Log it now! 🌈",
    "A quick note before bedtime? 🛌",
    "Your personal diary is waiting for today's entry! 💌",
    "Soft reminder: How was your day, star? ⭐",
    "Add a touch of color to your day with an emoji! 🎨",
    "Ready to close today's chapter? Add your note! 🌻",
    "Before you head to sleep, how was today? 🌌",
    "Sending you warm thoughts! Don't forget to log today! 🧸",
  ];

  static String getRandomMessage() {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
}
