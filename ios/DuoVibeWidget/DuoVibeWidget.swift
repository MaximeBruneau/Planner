import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            partnerName: "Partenaire",
            partnerEmoji: "🥰",
            status: "Humeur du jour ✨",
            isPaired: true,
            duoStreak: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = getEntry()
        // Refresh periodically (every 30 mins)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.vibecalendar.myDairy")
        let partnerName = userDefaults?.string(forKey: "partner_name") ?? "Partenaire"
        let partnerEmoji = userDefaults?.string(forKey: "partner_emoji") ?? ""
        let isPaired = userDefaults?.bool(forKey: "is_paired") ?? false
        let duoStreak = userDefaults?.integer(forKey: "duo_streak") ?? 0

        let status: String
        if !isPaired {
            status = "Connecte ton duo dans l'app"
        } else if !partnerEmoji.isEmpty {
            status = "Humeur du jour ✨"
        } else {
            status = "Pas encore rempli aujourd'hui 🌸"
        }

        return SimpleEntry(
            date: Date(),
            partnerName: partnerName,
            partnerEmoji: partnerEmoji,
            status: status,
            isPaired: isPaired,
            duoStreak: duoStreak
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let partnerName: String
    let partnerEmoji: String
    let status: String
    let isPaired: Bool
    let duoStreak: Int
}

struct DuoVibeWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.98),
                    Color(red: 1.0, green: 0.94, blue: 0.95),
                    Color(red: 1.0, green: 0.96, blue: 0.92)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 4) {
                // Header: Partner Name + Duo Streak Pill
                HStack {
                    Text("\(entry.partnerName)'s Vibe 🌸")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.25, green: 0.10, blue: 0.15))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if entry.duoStreak > 0 && entry.isPaired {
                        Text("🔥🔥 \(entry.duoStreak)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.90, green: 0.35, blue: 0.45))
                    }
                }
                
                Spacer()
                
                // Main Emoji Display
                if !entry.isPaired {
                    Text("🐰")
                        .font(.system(size: 44))
                } else if !entry.partnerEmoji.isEmpty {
                    Text(entry.partnerEmoji)
                        .font(.system(size: 46))
                } else {
                    Text("😴")
                        .font(.system(size: 40))
                }
                
                Spacer()
                
                // Status / Subtitle (Not filled yet today / Humeur enregistrée)
                Text(entry.status)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.45, green: 0.25, blue: 0.30))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(14)
        }
    }
}

@main
struct DuoVibeWidget: Widget {
    let kind: String = "DuoVibeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DuoVibeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DuoVibe Partner Vibe")
        .description("Affiche en direct l'émoji du jour de votre partenaire ou un message s'il n'a pas encore rempli.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
