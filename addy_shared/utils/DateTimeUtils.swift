//
//  DateTimeUtils.swift
//  addy_shared
//
//  Created by Stijn van de Water on 10/05/2024.
//

import Foundation

public enum DateTimeUtils {
    public enum DateTimeFormat {
        case date
        case time
        case dateTime
        case shortDate
    }

    public static func convertStringToLocalTimeZoneString(_ string: String?, dateTimeFormat: DateTimeFormat = .dateTime) -> String {
        guard let string = string else {
            return ""
        }

        do {
            let date = try turnStringIntoDate(string)

            switch dateTimeFormat {
            case .date:
                return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
            case .time:
                return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
            case .dateTime:
                return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
            case .shortDate:
                let formatter = DateFormatter()
                formatter.dateFormat = "E d MMM"
                return formatter.string(from: date)
            }
        } catch {
            return "\(string) (GMT)"
        }
    }

    public static func convertStringToLocalTimeZoneDate(_ string: String?) throws -> Date {
        return try turnStringIntoDate(string)
    }

    private static func turnStringIntoDate(_ string: String?) throws -> Date {
        guard let string = string else {
            throw NSError(domain: "Nil date string", code: 0, userInfo: nil)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: string) else {
            throw NSError(domain: "Invalid date string", code: 0, userInfo: nil)
        }
        return date
    }
}

