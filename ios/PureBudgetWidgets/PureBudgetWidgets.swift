import WidgetKit
import SwiftUI

struct BudgetEntry: TimelineEntry {
    let date: Date
    let fractionTotalBudget: String
    let totalText: String
    let backgroundColor: Color
}

struct BudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(
            date: Date(),
            fractionTotalBudget: "123",
            totalText: "from 456 € total",
            backgroundColor: Color.blue.opacity(0.8)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.jne_solutions.household")

        let fraction = defaults?.string(forKey: "fractionTotalBudget") ?? "0"
        let totalBudget = defaults?.string(forKey: "totalBudget") ?? "0"
        let currency = defaults?.string(forKey: "currency") ?? "€"
        let totalFrom = defaults?.string(forKey: "totalFrom") ?? "from"
        let totalConnector = defaults?.string(forKey: "totalConnector") ?? "total"
        let opacity = defaults?.integer(forKey: "backgroundOpacity") ?? 255
        let baseColor = Color.blue.opacity(Double(opacity) / 255.0)

        let formattedAmount = "\(totalBudget) \(currency)"
        let formattedFraction = "\(fraction) \(currency)"
        let totalText = "\(totalFrom) \(formattedAmount) \(totalConnector)"

        let entry = BudgetEntry(
            date: Date(),
            fractionTotalBudget: formattedFraction,
            totalText: totalText,
            backgroundColor: baseColor
        )

        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct PureBudgetWidgetsEntryView: View {
    var entry: BudgetProvider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(entry.fractionTotalBudget)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)

            Text(entry.totalText)
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(entry.backgroundColor)
        .widgetURL(URL(string: "jnehousehold://openApp"))
    }
}

struct PureBudgetWidgets: Widget {
    let kind: String = "PureBudgetWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetProvider()) { entry in
            PureBudgetWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Total Budget")
        .description("Shows your total household budget.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    PureBudgetWidgets()
} timeline: {
    BudgetEntry(date: .now, fractionTotalBudget: "123", totalText: "from 456 € total", backgroundColor: .black)
}
