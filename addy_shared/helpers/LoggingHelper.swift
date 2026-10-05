//
//  LoggingHelper.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

public class LoggingHelper {
    private let settingsManager: SettingsManager
    private let prefs: UserDefaults

    public enum LogFiles: String {
        case `default` = "host.stjin.addy_logs"
        case watchosLogs = "host.stjin.addy_logs.watchkit"
    }

    public init(logFile: LogFiles = .default) {
        settingsManager = SettingsManager(encrypted: false)
        prefs = UserDefaults(suiteName: logFile.rawValue) ?? UserDefaults.standard
    }

    private static let lock = NSRecursiveLock()

    public func setList(logs: [Logs]?) {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        let logsData = try? JSONEncoder().encode(logs?.suffix(100))
        prefs.set(logsData, forKey: "logs")
    }

    public func getLogs() -> [Logs]? {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        guard let logsData = prefs.data(forKey: "logs") else { return nil }
        return try? JSONDecoder().decode([Logs].self, from: logsData)
    }

    public func addLog(importance: LogImportance, error: String, method: String, extra: String?) {
        if settingsManager.getSettingsBool(key: .storeLogs) {
            Self.lock.lock()
            defer { Self.lock.unlock() }
            var logs = getLogs() ?? []
            logs.append(Logs(importance: importance, dateTime: getDateTime(), method: method, message: error, extra: extra))
            setList(logs: logs)
        }
    }

    public func clearLogs() {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        prefs.removeObject(forKey: "logs")
        addLog(importance: .info, error: NSLocalizedString("logs_cleared", bundle: Bundle(for: LoggingHelper.self), comment: ""), method: "clearLogs()", extra: nil)
    }

    private static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private func getDateTime() -> String {
        return Self.logDateFormatter.string(from: Date())
    }
}
