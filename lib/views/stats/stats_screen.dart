import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/mood_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _currentMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year,now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final moodMap = ref.watch(moodProvider);

    final monthPrefix = DateFormat('yyyy-MM').format(_selectedMonth);
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);

    // Filter entries for selected month
    final monthEntries = moodMap.entries
        .where((entry) => entry.key.startsWith(monthPrefix))
        .map((e) => e.value)
        .toList();

    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final monthLogCount = monthEntries.length;
    final logRate = daysInMonth > 0 ? (monthLogCount / daysInMonth) : 0.0;

    final overallStreak = _calculateStreak(moodMap);
    final emojiCounts = _calculateEmojiCounts(monthEntries);

    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Vibe Analytics 📊",
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _previousMonth,
                      tooltip: "Previous Month",
                    ),
                    InkWell(
                      onTap: _currentMonth,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Column(
                          children: [
                            Text(
                              monthName,
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (!isCurrentMonth)
                              Text(
                                "Tap to return to today",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _nextMonth,
                      tooltip: "Next Month",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Overview Cards Row for Selected Month
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Month Logs",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "$monthLogCount",
                                style: GoogleFonts.fredoka(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Text(
                                "/$daysInMonth days",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Logging Rate",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${(logRate * 100).toStringAsFixed(0)}%",
                            style: GoogleFonts.fredoka(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Active Streak Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text("🔥", style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current Streak",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            "$overallStreak Consecutive Days",
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Month Mood Distribution Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mood Distribution ($monthName) 🌈",
                      style: GoogleFonts.fredoka(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (emojiCounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            "No vibe entries logged for $monthName yet! 🌸",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: emojiCounts.entries.map((entry) {
                          final emoji = entry.key;
                          final count = entry.value;
                          final percentage = (count / monthLogCount);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "$count times",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            "${(percentage * 100).toStringAsFixed(0)}%",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: percentage,
                                          minHeight: 8,
                                          backgroundColor: colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(Map<String, dynamic> moodMap) {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    final todayStr = DateFormat('yyyy-MM-dd').format(checkDate);

    // Check today first, if not filled check yesterday
    if (!moodMap.containsKey(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(checkDate);
      if (moodMap.containsKey(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Map<String, int> _calculateEmojiCounts(List<dynamic> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      final emoji = entry.emoji as String;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    // Sort descending by count
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }
}
