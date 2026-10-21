//
//  ServiceStatus.swift
//  addy_shared
//
//  Created by Stijn van de Water on 21/10/2026.
//

import Foundation

public struct ServiceStatus: Codable, Sendable, Equatable {
    public let title: String?
    public let timezone: String?
    public let pinnedUpdate: StatusUpdate?
    public let monitors: [String: [StatusMonitor]]?
    public let updatesPerDay: [String: [StatusUpdate]]?
    public let summarizedStatus: String?

    public init(
        title: String? = nil,
        timezone: String? = nil,
        pinnedUpdate: StatusUpdate? = nil,
        monitors: [String: [StatusMonitor]]? = nil,
        updatesPerDay: [String: [StatusUpdate]]? = nil,
        summarizedStatus: String? = nil
    ) {
        self.title = title
        self.timezone = timezone
        self.pinnedUpdate = pinnedUpdate
        self.monitors = monitors
        self.updatesPerDay = updatesPerDay
        self.summarizedStatus = summarizedStatus
    }

    public var isOperational: Bool {
        return summarizedStatus?.lowercased() == "up"
    }

    /// Finds the most relevant status update (pinned update first, or the most recent update across days).
    public var latestUpdate: StatusUpdate? {
        if let pinned = pinnedUpdate {
            return pinned
        }
        guard let updatesPerDay = updatesPerDay else { return nil }
        var allUpdates: [StatusUpdate] = []
        for (_, updates) in updatesPerDay {
            allUpdates.append(contentsOf: updates)
        }
        return allUpdates.max(by: { ($0.time ?? 0) < ($1.time ?? 0) })
    }

    /// Returns the status of the web application monitor if available
    public var webApplicationStatus: String? {
        guard let monitors = monitors else { return nil }
        for (_, monitorList) in monitors {
            for monitor in monitorList {
                if let label = monitor.label?.lowercased(), label.contains("web app") || label.contains("application") {
                    return monitor.status
                }
                if let url = monitor.url?.lowercased(), url.contains("app.addy.io") {
                    return monitor.status
                }
            }
        }
        return nil
    }
}

public struct StatusUpdate: Codable, Sendable, Equatable {
    public let id: Int?
    public let title: String?
    public let text: String?
    public let pinned: Bool?
    public let severity: String?
    public let time: Int?

    public init(
        id: Int? = nil,
        title: String? = nil,
        text: String? = nil,
        pinned: Bool? = nil,
        severity: String? = nil,
        time: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.pinned = pinned
        self.severity = severity
        self.time = time
    }
}

public struct StatusMonitor: Codable, Sendable, Equatable {
    public let label: String?
    public let url: String?
    public let status: String?

    public init(
        label: String? = nil,
        url: String? = nil,
        status: String? = nil
    ) {
        self.label = label
        self.url = url
        self.status = status
    }
}
