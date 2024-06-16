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
        }
        
        // Format the date into a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: self)
    }
}
