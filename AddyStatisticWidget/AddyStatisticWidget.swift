//
//  AddyStatisticWidget.swift
//  AddyStatisticWidget
//
//  Created by Stijn van de Water on 18/07/2024.
//

import WidgetKit
import SwiftUI
import addy_shared




private func getUserResource() -> UserResource? {
    return CacheHelper.getBackgroundServiceCacheUserResource()
    
}

private func getMostActiveAliasesData() -> [Aliases]? {
    let aliases = CacheHelper.getBackgroundServiceCacheMostActiveAliasesData()
    return Array(aliases?.prefix(5) ?? [])
}

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
            case .accessoryCircular:
                
                Gauge(
                    value: Double(userResource.bandwidth), in: 0...Double(userResource.bandwidth_limit),
                    label: { Text(String(localized: "widget_1_bandwidth_gauge")) },
                    currentValueLabel: { Text(String(userResource.bandwidth/1024/1024)) },
                    minimumValueLabel: { Text("0") },
                    maximumValueLabel: { Text(userResource.bandwidth_limit == 0 ? "∞" : String(userResource.bandwidth_limit/1024/1024)) }
                ).gaugeStyle(.accessoryCircular)
                
            case .accessoryRectangular:
                VStack(alignment: .leading) {
                    Label {
                        Text(String(localized: "app_name"))
                    } icon: {
                        Image("AddyLogo")
                            .apply {
                                if entry.configuration.colorfulBackground {
                                    $0.renderingMode(.template).resizable()
                                        .resizable().scaledToFit().frame(maxHeight: 16)
                                        .widgetAccentable()
                                        .foregroundColor(.white)
                                } else {
                                    $0.resizable()
                                        .resizable().scaledToFit().frame(maxHeight: 16)
                                        .widgetAccentable()
                                }
                            }
                    }
                    Text(String(localized: "monthly_bandwidth")).frame(maxHeight: .infinity)
                    Gauge(
                        value: Double(userResource.bandwidth), in: 0...Double(userResource.bandwidth_limit),
                        label: { Text(String(localized: "widget_1_bandwidth_gauge")) },
                        currentValueLabel: { Text(String(userResource.bandwidth/1024/1024)) },
                        minimumValueLabel: { Text("0") },
                        maximumValueLabel: { Text(userResource.bandwidth_limit == 0 ? "∞" : String(userResource.bandwidth_limit/1024/1024)) }
                    ).gaugeStyle(.accessoryLinear)
                    
                }
            case .accessoryInline:
                Text(String(format: String(localized: "widget_1_inline_text"), "\(userResource.total_emails_forwarded)")).frame(maxHeight: .infinity)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.2), value: userResource.total_emails_forwarded)
                //case .systemSmall:
                // Fall back to default for unknown sizes
            case .systemLarge:
                largeWidgetSize(userResource: userResource, entry: entry)
                
            case .systemExtraLarge:
                mediumWidgetSize(userResource: userResource, entry: entry)
                
            case .systemMedium:
                mediumWidgetSize(userResource: userResource, entry: entry)
                
            default:
                VStack {
                    Image("AddyLogo").apply {
                        if entry.configuration.colorfulBackground {
                            $0.renderingMode(.template).resizable().scaledToFit().frame(maxHeight: 30).frame(maxWidth: .infinity, alignment: .trailing).foregroundColor(.white)
                        } else {
                            $0.resizable().scaledToFit().frame(maxHeight: 30).frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }.widgetAccentable()
                    Spacer()
                    Text(userResource.total_emails_forwarded, format: .number).font(.system(size: 40)).fontWeight(.bold).minimumScaleFactor(0.1).frame(maxWidth: .infinity, alignment: .leading)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.2), value: userResource.total_emails_forwarded).foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
                    Text("emails_forwarded").minimumScaleFactor(0.1).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
                }
                
            }
            
            
            
        } else {
            ContentUnavailableView {
                Text(String(localized: "app_not_setup")).minimumScaleFactor(0.1).foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
            } description: {
                Text("app_not_setup_desc").minimumScaleFactor(0.1).foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
            }
        }
    }
    
}


struct mediumWidgetSize: View {
    var userResource: UserResource
    var entry: Provider.Entry
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(spacing: 4) {
                HStack(alignment: .center) {
                    Text(userResource.total_emails_forwarded, format: .number).font(.system(size: 40)).fontWeight(.bold).minimumScaleFactor(0.1).lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.2), value: userResource.total_emails_forwarded)
                    Text("forwarded").minimumScaleFactor(0.1).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .center) {
                    Text(userResource.total_emails_blocked, format: .number).font(.system(size: 40)).fontWeight(.bold).minimumScaleFactor(0.1).lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.2), value: userResource.total_emails_blocked)
                    Text("blocked").minimumScaleFactor(0.1).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .center) {
                    Text(userResource.total_emails_sent, format: .number).font(.system(size: 40)).fontWeight(.bold).minimumScaleFactor(0.1).lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.2), value: userResource.total_emails_sent)
                    Text("sent").minimumScaleFactor(0.1).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .center) {
                    Text(userResource.total_emails_replied, format: .number).font(.system(size: 40)).fontWeight(.bold).minimumScaleFactor(0.1).lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.2), value: userResource.total_emails_replied)
                    Text("replied").minimumScaleFactor(0.1).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.frame(maxWidth: .infinity).foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
            
            VStack {
                Image("AddyLogo").apply {
                    if entry.configuration.colorfulBackground {
                        $0.renderingMode(.template).resizable().scaledToFit().frame(maxHeight: 30).frame(alignment: .trailing).foregroundColor(.white)
                    } else {
                        $0.resizable().scaledToFit().frame(maxHeight: 30).frame(alignment: .trailing)
                    }
                }.widgetAccentable()
            }
        }
    }
}

struct largeWidgetSize: View {
    var userResource: UserResource
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text(String(localized: "most_active_aliases")).font(.system(size: 18)).fontWeight(.medium).minimumScaleFactor(0.1).lineLimit(1).foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
                Spacer()
                Image("AddyLogo").apply {
                    if entry.configuration.colorfulBackground {
                        $0.renderingMode(.template).resizable().scaledToFit().frame(maxHeight: 30).foregroundColor(.white)
                    } else {
                        $0.resizable().scaledToFit().frame(maxHeight: 30)
                    }
                }.widgetAccentable()
                
                
            }.frame(maxWidth: .infinity, minHeight: 30)
            
            VStack(spacing: 0) {
                
                if let aliases = getMostActiveAliasesData() {
                    ForEach(Array(aliases.enumerated()), id: \.1) { (index, alias) in
                        AliasWidgetRowView(alias: alias, entry: entry)
                        
                        // Show divider for all but the last item
                        if index < aliases.count - 1 {
                            Divider().background(entry.configuration.colorfulBackground ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                        }
                    }
                }
                
                
            }
            .background(ContainerRelativeShape().fill(.white.opacity(0.15)))
            .frame(maxHeight: .infinity)
        }
    }
}



struct AliasWidgetRowView: View {
    @State var alias: Aliases
    @State var aliasDescription: String = ""
    var entry: Provider.Entry
    
    
    var body: some View {
        Link(destination: URL(string: "addyio://alias/\(alias.id)")!) {
            HStack() {
                VStack(alignment: .leading) {
                    Text(SettingsManager(encrypted: true).getSettingsBool(key: .privacyMode) ? String(localized: "alias_hidden") : alias.email)
                        .font(.system(size: 16))
                        .foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(aliasDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onAppear {
                            if let description = alias.description {
                                aliasDescription =  String(format: String(localized: "s_s_s"),
                                                           description,
                                                           String(format: NSLocalizedString("created_at_s", comment: ""),
                                                                  DateTimeUtils.turnStringIntoLocalString(alias.created_at)),
                                                           String(format: String(localized: "updated_at_s"),
                                                                  DateTimeUtils.turnStringIntoLocalString(alias.updated_at)))
                            } else {
                                aliasDescription =  String(format: String(localized: "s_s"),
                                                           String(format: NSLocalizedString("created_at_s", comment: ""),
                                                                  DateTimeUtils.turnStringIntoLocalString(alias.created_at)),
                                                           String(format: String(localized: "updated_at_s"),
                                                                  DateTimeUtils.turnStringIntoLocalString(alias.updated_at)))
                            }
                        }
                }
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(entry.configuration.colorfulBackground ? .white : .revertedNightMode)
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal)

        }
        
    }
    
}

struct AddyStatisticWidget: Widget {
    let kind: String = "AddyStatisticWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            AddyStatisticWidgetEntryView(entry: entry)
                .containerBackground(entry.configuration.colorfulBackground ? LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.30, green: 0.60, blue: 0.71),
                        Color(red: 0.24, green: 0.28, blue: 0.51)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ) : LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.tertiarySystemFill),
                        Color(UIColor.tertiarySystemFill)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ), for: .widget)
            
            
        }
        .configurationDisplayName(String(localized: "widget_1_name"))
        .description(String(localized: "widget_1_description"))
        .supportedFamilies(
            [
                .systemSmall,
                .systemMedium,
                .systemLarge,
                .systemExtraLarge,
                .accessoryInline,
                .accessoryCircular,
                .accessoryRectangular
            ]
        )
    }
}

extension ConfigurationAppIntent {
    fileprivate static var plain: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.colorfulBackground = false
        return intent
    }
    
    fileprivate static var colorful: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.colorfulBackground = true
        return intent
    }
}



#Preview(as: .systemSmall) {
    AddyStatisticWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .plain)
    SimpleEntry(date: .now, configuration: .colorful)
}
