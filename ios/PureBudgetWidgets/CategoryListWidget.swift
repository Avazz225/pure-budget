import WidgetKit
import SwiftUI

// MARK: - Entry
struct CategoryEntry: TimelineEntry {
    let date: Date
    let categories: [CategoryData]
    let currency: String
    let totalFrom: String
    let totalConnector: String
}

// MARK: - Category Data Model
struct CategoryData: Identifiable {
    let id: Int
    let name: String
    let total: String
    let fraction: String
    let backgroundColor: Color
    let textColor: Color
}

// MARK: - Timeline Provider
struct CategoriesProvider: TimelineProvider {
    func placeholder(in context: Context) -> CategoryEntry {
        CategoryEntry(
            date: Date(),
            categories: [],
            currency: "€",
            totalFrom: "from",
            totalConnector: "total"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CategoryEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CategoryEntry>) -> Void) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func loadEntry() -> CategoryEntry {
        let defaults = UserDefaults(suiteName: "group.pureBudgetIOS")

        let currency = defaults?.string(forKey: "currency") ?? "€"
        let totalFrom = defaults?.string(forKey: "totalFrom") ?? "from"
        let totalConnector = defaults?.string(forKey: "totalConnector") ?? "total"
        let jsonString = defaults?.string(forKey: "categoryList") ?? "[]"

        let categories: [CategoryData]
        if let data = jsonString.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            categories = array.map { dict in
                let id = dict["id"] as? Int ?? 0
                let name = dict["name"] as? String ?? ""
                let total = dict["total"] as? String ?? "0"
                let fraction = dict["fraction"] as? String ?? "0"
                let bgR = dict["colorR"] as? Double ?? 0
                let bgG = dict["colorG"] as? Double ?? 0
                let bgB = dict["colorB"] as? Double ?? 0
                let bgA = dict["colorA"] as? Double ?? 255
                let txtR = dict["textColorR"] as? Double ?? 255
                let txtG = dict["textColorG"] as? Double ?? 255
                let txtB = dict["textColorB"] as? Double ?? 255
                let txtA = dict["textColorA"] as? Double ?? 255

                return CategoryData(
                    id: id,
                    name: name,
                    total: total,
                    fraction: fraction,
                    backgroundColor: Color(
                        red: bgR / 255,
                        green: bgG / 255,
                        blue: bgB / 255,
                        opacity: bgA / 255
                    ),
                    textColor: Color(
                        red: txtR / 255,
                        green: txtG / 255,
                        blue: txtB / 255,
                        opacity: txtA / 255
                    )
                )
            }
        } else {
            categories = []
        }

        return CategoryEntry(
            date: Date(),
            categories: categories,
            currency: currency,
            totalFrom: totalFrom,
            totalConnector: totalConnector
        )
    }
}

// MARK: - Widget View
struct CategoriesWidgetEntryView: View {
    @Environment(\.colorScheme) var colorScheme
    let entry: CategoryEntry

    var body: some View {
        GeometryReader { geo in
            let maxItems = calculateMaxItems(widgetHeight: geo.size.height)
            
            VStack(spacing: 4) {
                ForEach(entry.categories.prefix(maxItems)) { category in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.headline)
                                .foregroundColor(category.textColor)
                            Text("\(category.fraction) \(entry.totalFrom) \(category.total) \(entry.totalConnector)")
                                .font(.caption)
                                .foregroundColor(category.textColor)
                        }
                        Spacer()
                        Link(destination: URL(string: "PureBudget://addExpense?categoryId=\(category.id)")!) {
                            Text("+")
                                .font(.title2.bold())
                                .foregroundColor(category.textColor)
                        }
                    }
                    .padding(6)
                    .background(category.backgroundColor)
                    .cornerRadius(8)
                }
            }
            .padding(8)
            .containerBackground(for: .widget) {colorScheme == .dark ? Color.black : Color.white}
        }
    }

    private func calculateMaxItems(widgetHeight: CGFloat, itemHeight: CGFloat = 56, spacing: CGFloat = 4) -> Int {
        return max(Int((widgetHeight + spacing) / (itemHeight + spacing)), 1)
    }
}

// MARK: - Widget Definition
struct CategoriesWidget: Widget {
    let kind: String = "CategoriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CategoriesProvider()) { entry in
            CategoriesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("WIDGET_CATEGORIES_TITLE", comment: "Title of the categories widget"))
        .description(NSLocalizedString("WIDGET_CATEGORIES_DESCRIPTION", comment: "Description of the categories widget"))
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    }
}
