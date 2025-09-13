import WidgetKit
import SwiftUI

struct TotalBudgetEntry: TimelineEntry {
    let date: Date
    let fractionTotalBudget: String
    let totalText: String
    let backgroundColor: Color
}

struct TotalBudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TotalBudgetEntry {
        TotalBudgetEntry(
            date: Date(),
            fractionTotalBudget: "123",
            totalText: "from 456 € total",
            backgroundColor: Color.blue.opacity(0.8)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TotalBudgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TotalBudgetEntry>) -> Void) {
        let entry = loadEntry()

        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func loadEntry() -> TotalBudgetEntry {
        let defaults = UserDefaults(suiteName: "group.pureBudgetIOS")

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

        return TotalBudgetEntry(
            date: Date(),
            fractionTotalBudget: formattedFraction,
            totalText: totalText,
            backgroundColor: baseColor
        )
    }
}

struct TotalBudgetWidgetEntryView: View {
    @Environment(\.colorScheme) var colorScheme
    var entry: TotalBudgetProvider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(entry.fractionTotalBudget)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            Text(entry.totalText)
                .font(.system(size: 18))
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color.black : Color.white
        }
        .widgetURL(URL(string: "jnehousehold://"))
    }
}

struct TotalBudgetWidget: Widget {
    let kind: String = "TotalBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TotalBudgetProvider()) { entry in
            TotalBudgetWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("WIDGET_TOTAL_BUDGET_TITLE", comment: "Title of the total budget widget"))
        .description(NSLocalizedString("WIDGET_TOTAL_BUDGET_DESCRIPTION", comment: "Description of the total budget widget"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
