//
//  LogsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 11/06/2024.
//

import addy_shared
import Combine
import SwiftUI

// Marked as @MainActor to ensure all @Published updates
// happen on the main thread and resolve Sendable warnings.
@MainActor
class LogsViewModel: ObservableObject {
    @Published var logs: [Logs]? = nil
    @Published var isLoading = false
    
    private var watchosLogs: Bool

    init(watchosLogs: Bool) {
        self.watchosLogs = watchosLogs
        getLogs()
    }

    func getWatchOsLogs() {
        if !isLoading {
            self.isLoading = true
            // Accessing local logs is synchronous, but we still
            // wrap it in the MainActor context of the class.
            self.logs = LoggingHelper(logFile: .watchosLogs).getLogs()?.reversed() ?? []
            self.isLoading = false
        }
    }
    
    func getLogs() {
        if watchosLogs {
            getWatchOsLogs()
        } else {
            getDeviceLogs()
        }
    }
    
    func getDeviceLogs() {
        if !isLoading {
            self.isLoading = true
            self.logs = LoggingHelper().getLogs()?.reversed() ?? []
            self.isLoading = false
        }
    }
}
