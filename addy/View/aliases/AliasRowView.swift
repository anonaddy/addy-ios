//
//  AliasRowView.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import addy_shared
import SwiftUI

struct AliasRowView: View {
    let alias: Aliases
    let isPreview: Bool
    private var chartData: [Double] {
        let total = Double(alias.emails_forwarded + alias.emails_replied + alias.emails_sent + alias.emails_blocked)
        let normalizedTotal = total != 0 ? total : 10.0

        return [
            Double(alias.emails_forwarded) / normalizedTotal * 100,
            Double(alias.emails_replied) / normalizedTotal * 100,
            Double(alias.emails_sent) / normalizedTotal * 100,
            Double(alias.emails_blocked) / normalizedTotal * 100,
        ]
    }

    private var aliasDescription: String {
        localizedDateText(for: alias)
    }

    private var isWatchingAlias: Bool {
        AliasWatcher().getAliasesToWatch().contains(alias.id)
    }

    private var chartColors: [ColorGradient] {
        [
            ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
            ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
            ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
            ColorGradient(.softRed, .softRed.opacity(0.7)),
        ]
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        Group {
            if isPreview {
                previewBody
            } else {
                listBody
            }
        }
    }

    private var previewBody: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(verbatim: alias.email)
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(alignment: .center) {
                    chartView(width: 100)

                    Spacer()

                    statsLabels
                }
            }

            if isWatchingAlias {
                Label(String(localized: "you_ll_be_notified_if_this_alias_has_activity"), systemImage: "eyes")
                    .foregroundStyle(.gray.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.vertical, 4)
            }
        }.overlay(alignment: .topTrailing) {
            if alias.pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10)) // "Tiny" as requested
                    .foregroundColor(.secondary)
                    .padding(.top, 8) // Adjust these to sit nicely
                    .padding(.trailing, 4) // within your list row padding
            }
        }
        .padding()
    }

    private var listBody: some View {
        HStack {
            chartView(width: 50)
                .grayscale(alias.active ? 0 : 1)
                .padding(.trailing)

            VStack(alignment: .leading) {
                Text(alias.email)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(aliasDescription)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 90)
        .overlay(alignment: .topTrailing) {
            if alias.pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10)) // "Tiny" as requested
                    .foregroundColor(.secondary)
                    .padding(.top, 8) // Adjust these to sit nicely
                    .padding(.trailing, 4) // within your list row padding
            }
        }
    }

    private func chartView(width: CGFloat) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                BarChart()
                    .data(chartData)
                    .chartStyle(ChartStyle(backgroundColor: .white, foregroundColor: chartColors))
                    .allowsHitTesting(false)
                    .padding(.horizontal)
                    .padding(.top)
            }
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .frame(maxWidth: width)
    }

    private var statsLabels: some View {
        VStack(alignment: .trailing) {
            statsLabel("tray", String(format: String(localized: "d_forwarded", comment: ""), "\(alias.emails_forwarded)"), .portalOrange)
            statsLabel("arrow.turn.up.left", String(format: String(localized: "d_replied", comment: ""), "\(alias.emails_replied)"), .easternBlue)
            statsLabel("paperplane", String(format: String(localized: "d_sent", comment: ""), "\(alias.emails_sent)"), .portalBlue)
            statsLabel("slash.circle", String(format: String(localized: "d_blocked", comment: ""), "\(alias.emails_blocked)"), .softRed)
        }
        .labelStyle(MyAliasLabelStyle())
    }

    private func statsLabel(_ systemImage: String, _ string: String, _ color: Color) -> some View {
        Label(title: {
            Text(string)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .lineLimit(1)
        }, icon: {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .font(.system(size: 18, weight: .bold))
        })
    }
}

// MARK: - Date Formatting Helpers

private func localizedDate(_ dateString: String) -> String {
    do {
        return try DateTimeUtils
            .convertStringToLocalTimeZoneDate(dateString)
            .aliasRowDateDisplay()
    } catch {
        return DateTimeUtils.convertStringToLocalTimeZoneString(dateString)
    }
}

private func deletedText(_ deletedAt: String) -> String {
    String(format: NSLocalizedString("deleted_at_s", comment: ""), localizedDate(deletedAt))
}

private func createdText(_ createdAt: String) -> String {
    String(format: NSLocalizedString("created_at_s", bundle: Bundle(for: SharedData.self), comment: ""), localizedDate(createdAt))
}

private func updatedText(_ updatedAt: String) -> String {
    String(format: NSLocalizedString("updated_at_s", comment: ""), localizedDate(updatedAt))
}

private func localizedDateText(for alias: Aliases) -> String {
    if let deletedAt = alias.deleted_at {
        if let description = alias.description {
            // "<description> · deleted <date>"
            return String(format: String(localized: "s_s"), description, deletedText(deletedAt))
        } else {
            // "deleted <date> · created <date>"
            return String(format: String(localized: "s_s"), deletedText(deletedAt), createdText(alias.created_at))
        }
    } else if let description = alias.description {
        // "<description> · created <date> · updated <date>"
        return String(format: String(localized: "s_s_s"), description, createdText(alias.created_at), updatedText(alias.updated_at))
    } else {
        // "created <date> · updated <date>"
        return String(format: String(localized: "s_s"), createdText(alias.created_at), updatedText(alias.updated_at))
    }
}

// #Preview {
//     AliasRowCardView()
// }
