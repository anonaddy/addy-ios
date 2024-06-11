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
        //case backupLogs = "host.stjin.anonaddy_logs_backups"
        //case watchosLogs = "host.stjin.anonaddy_logs_watchos"
    }

    public init(logFile: LogFiles = .default) {
        self.settingsManager = SettingsManager(encrypted: false)
        self.prefs = UserDefaults(suiteName: logFile.rawValue)!
    }

    private func setList(logs: [Logs]?) {
        let logsData = try? JSONEncoder().encode(logs?.suffix(100))
        prefs.set(logsData, forKey: "logs")
    }

    public func getLogs() -> [Logs]? {
        guard let logsData = prefs.data(forKey: "logs") else { return nil }
        return try? JSONDecoder().decode([Logs].self, from: logsData)
    }

    public func addLog(importance: LogImportance, error: String, method: String, extra: String?) {
        if settingsManager.getSettingsBool(key: .storeLogs) {
            var logs = getLogs() ?? []
            logs.append(Logs(importance: importance, dateTime: getDateTime(), method: method, message: error, extra: extra))
            setList(logs: logs)
        }
    }

    public func clearLogs() {
        prefs.removeObject(forKey: "logs")
        addLog(importance: .info, error: String(localized: "logs_cleared"), method: "getLogs()", extra: nil)
    }

    private func getDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}
