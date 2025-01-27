//
//  PrettyTime.swift
//  addy
//
//  Created by Stijn van de Water on 16/06/2024.
//

import Foundation

extension Date {
    func futureDateDisplay() -> String {
        let calendar = Calendar.current
        let minutesUntil = calendar.date(byAdding: .minute, value: 1, to: Date())!
        let hourUntil = calendar.date(byAdding: .hour, value: 1, to: Date())!
        let dayUntil = calendar.date(byAdding: .day, value: 1, to: Date())!
        let weekUntil = calendar.date(byAdding: .day, value: 7, to: Date())!
        let monthUntil = calendar.date(byAdding: .month, value: 1, to: Date())!
        let yearUntil = calendar.date(byAdding: .year, value: 1, to: Date())!

        if minutesUntil > self {
            let diff = Calendar.current.dateComponents([.second], from: Date(), to: self).second ?? 0
            return String(format: NSLocalizedString("d_sec_from_now_on", comment: ""), diff)
        } else if hourUntil > self {
            let diff = Calendar.current.dateComponents([.minute], from: Date(), to: self).minute ?? 0
            return String(format: NSLocalizedString("d_min_from_now_on", comment: ""), diff)
        } else if dayUntil > self {
            let diff = Calendar.current.dateComponents([.hour], from: Date(), to: self).hour ?? 0
            return String(format: NSLocalizedString("d_hrs_from_now_on", comment: ""), diff)
        } else if weekUntil > self {
            let diff = Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
            return String(format: NSLocalizedString("d_days_from_now_on", comment: ""), diff)
        } else if monthUntil > self {
            let diff = Calendar.current.dateComponents([.weekOfMonth], from: Date(), to: self).weekOfMonth ?? 0
            return String(format: NSLocalizedString("d_weeks_from_now_on", comment: ""), diff)
        } else if yearUntil > self {
            let diff = Calendar.current.dateComponents([.month], from: Date(), to: self).month ?? 0
            return String(format: NSLocalizedString("d_months_from_now_on", comment: ""), diff)
        } else {
            // If more than one year in the future, format as years
            let diff = Calendar.current.dateComponents([.year], from: Date(), to: self).year ?? 0
            if diff > 1 {
                return String(format: NSLocalizedString("d_years_from_now_on", comment: ""), diff)
            } else {
                // Format the date into a string for dates exactly one year from now or for some reason not caught by previous conditions
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                return dateFormatter.string(from: self)
            }
        }
    }
    
    func aliasRowDateDisplay() -> String {
        let calendar = Calendar.current
        let currentDate = Date()
        
        if calendar.isDateInToday(self) {
            let diffSeconds = calendar.dateComponents([.second], from: self, to: currentDate).second ?? 0
            if diffSeconds == 0 {
                return NSLocalizedString("just_now", comment: "")
            } else if diffSeconds < 60 {
                return String(format: NSLocalizedString("d_sec_ago", comment: ""), diffSeconds)
            } else {
                let diffMinutes = calendar.dateComponents([.minute], from: self, to: currentDate).minute ?? 0
                if diffMinutes == 0 {
                    return String(format: NSLocalizedString("d_sec_ago", comment: ""), diffSeconds)
                } else if diffMinutes < 60 {
                    return String(format: NSLocalizedString("d_min_ago", comment: ""), diffMinutes)
                } else {
                    let diffHours = calendar.dateComponents([.hour], from: self, to: currentDate).hour ?? 0
                    if diffHours < 24 {
                        if diffHours == 1 {
                            return NSLocalizedString("1_hour_ago", comment: "")
                        } else {
                            return String(format: NSLocalizedString("d_hours_ago", comment: ""), diffHours)
                        }
                    } else {
                        let diffDays = calendar.dateComponents([.day], from: self, to: currentDate).day ?? 0
                        if diffDays < 30 {
                            if diffDays == 1 {
                                return NSLocalizedString("1_day_ago", comment: "")
                            } else {
                                return String(format: NSLocalizedString("d_days_ago", comment: ""), diffDays)
                            }
                        } else {
                            let diffMonths = calendar.dateComponents([.month], from: self, to: currentDate).month ?? 0
                            if diffMonths < 12 {
                                if diffMonths == 1 {
                                    return NSLocalizedString("1_month_ago", comment: "")
                                } else {
                                    return String(format: NSLocalizedString("d_months_ago", comment: ""), diffMonths)
                                }
                            } else {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateStyle = .medium
                                dateFormatter.timeStyle = .none
                                return dateFormatter.string(from: self)
                            }
                        }
                    }
                }
            }
        } else if calendar.isDateInYesterday(self) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            timeFormatter.dateStyle = .none
            return String(format: NSLocalizedString("yesterday_at", comment: ""), timeFormatter.string(from: self))
        } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: currentDate), self >= weekAgo {
            let weekday = calendar.component(.weekday, from: self)
            let dayName = DateFormatter().weekdaySymbols[weekday - 1].lowercased()
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            timeFormatter.dateStyle = .none
            return String(format: NSLocalizedString("last_d_at", comment: ""), dayName, timeFormatter.string(from: self))
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: self)
        }
    }
}
