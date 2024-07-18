//
//  AddyStatisticWidget.swift
//  AddyStatisticWidget
//
//  Created by Stijn van de Water on 18/07/2024.
//

import WidgetKit
import SwiftUI
import addy_shared

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct AddyStatisticWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        
        if let userResource = getUserResource() {
            
            switch family {
                    //case .accessoryCircular:
                        // Code to construct the view for the circular accessory widget or watch complication.
                    //case .accessoryRectangular:
                        // Code to construct the view for the rectangular accessory widget or watch complication.
                    //case .accessoryInline:
                        // Code to construct the view for the inline accessory widget or watch complication.
                    //case .systemSmall:
                        // Code to construct the view for the small widget.
                    //case .systemLarge:
                        // Code to construct the view for the large widget.
                    case .systemMedium:
                HStack {
                    VStack {
                        Image("AddyLogo").resizable().scaledToFit().frame(maxHeight: 30).frame(maxWidth: .infinity, alignment: .leading)
                        Text(userResource.total_emails_forwarded, format: .number).font(.system(size: 40)).fontWeight(.bold).minimumScaleFactor(0.1).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.2), value: userResource.total_emails_forwarded)
                        Text("emails_forwarded").minimumScaleFactor(0.1).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(spacing: 16) {
                        HStack(alignment: .center) {
                            Text(userResource.total_emails_blocked, format: .number).font(.system(size: 20)).fontWeight(.bold).minimumScaleFactor(0.1).lineLimit(1)
                                .contentTransition(.numericText())
                                .animation(.spring(duration: 0.2), value: userResource.total_emails_blocked)
                            Text("blocked").minimumScaleFactor(0.1).lineLimit(1)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                        HStack(alignment: .center) {
                            Text(userResource.total_emails_sent, format: .number).font(.system(size: 20)).fontWeight(.bold).minimumScaleFactor(0.1).lineLimit(1)
                                .contentTransition(.numericText())
                                .animation(.spring(duration: 0.2), value: userResource.total_emails_sent)
                            Text("sent").minimumScaleFactor(0.1).lineLimit(1)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                        HStack(alignment: .center) {
                            Text(userResource.total_emails_replied, format: .number).font(.system(size: 20)).fontWeight(.bold).minimumScaleFactor(0.1).lineLimit(1)
                                .contentTransition(.numericText())
                                .animation(.spring(duration: 0.2), value: userResource.total_emails_replied)
                            Text("replied").minimumScaleFactor(0.1).lineLimit(1)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                        
                    default:
                        VStack {
                            Image("AddyLogo").resizable().scaledToFit().frame(maxHeight: 30).frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Text(userResource.total_emails_forwarded, format: .number).font(.system(size: 40)).fontWeight(.bold).minimumScaleFactor(0.1).frame(maxWidth: .infinity, alignment: .leading)
                                .contentTransition(.numericText())
                                    .animation(.spring(duration: 0.2), value: userResource.total_emails_forwarded)
                            Text("emails_forwarded").minimumScaleFactor(0.1).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
            
            
            
        } else {
            ContentUnavailableView {
                Text(String(localized: "app_not_setup")).minimumScaleFactor(0.1)
            } description: {
                Text("app_not_setup_desc").minimumScaleFactor(0.1)
            }
        }
    }
    
    func getUserResource() -> UserResource?{
        let encryptedSettingsManager = SettingsManager(encrypted: true)

        if let jsonString = encryptedSettingsManager.getSettingsString(key: .userResource),
           let jsonData = jsonString.data(using: .utf8) {
            let decoder = JSONDecoder()
            return try? decoder.decode(UserResource.self, from: jsonData)
        }
        return nil
    }
}

struct AddyStatisticWidget: Widget {
    let kind: String = "AddyStatisticWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            AddyStatisticWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}



#Preview(as: .systemSmall) {
    AddyStatisticWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
