//
//  DateTimeUtils.swift
//  addy_shared
//
//  Created by Stijn van de Water on 10/05/2024.
//

import Foundation

public struct DateTimeUtils {
    
    public enum DateTimeFormat {
        case date
        case time
        case dateTime
        case shortDate
    }
    
    public static func turnStringIntoLocalString(_ string: String?, dateTimeFormat: DateTimeFormat = .dateTime) -> String {
        guard let string = string else {
            return ""
        }
        
        do {
            let ldt = try turnStringIntoLocalDateTime(string)
            let serverZoneId = TimeZone(identifier: "GMT")
            let zonedDateTime = ldt.toDate(timeZone: serverZoneId!)
            let defaultZoneId = TimeZone.current
            
            let nyDateTime = zonedDateTime.toDate(timeZone: defaultZoneId)
            
            switch dateTimeFormat {
            case .date:
                return DateFormatter.localizedString(from: nyDateTime, dateStyle: .short, timeStyle: .none)
            case .time:
                return DateFormatter.localizedString(from: nyDateTime, dateStyle: .none, timeStyle: .short)
            case .dateTime:
                return DateFormatter.localizedString(from: nyDateTime, dateStyle: .short, timeStyle: .short)
            case .shortDate:
                let formatter = DateFormatter()
                formatter.dateFormat = "E d MMM"
                return formatter.string(from: nyDateTime)
            }
        } catch {
            return "\(string) (GMT)"
        }
    }
    
    public static func turnStringIntoLocalDateTime(_ string: String?) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: string!) else {
            throw NSError(domain: "Invalid date string", code: 0, userInfo: nil)
        }
        return date
    }
}

extension Date {
    func toDate(timeZone: TimeZone) -> Date {
        let seconds = TimeInterval(timeZone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}
