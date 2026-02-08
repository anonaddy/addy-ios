//
//  LogsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 11/06/2024.
//

import addy_shared
import Combine
import SwiftUI

class LogsViewModel: ObservableObject {
    @Published var logs: [Logs]? = nil
    @Published var isLoading = false
    @State private var watchosLogs: Bool

    init(watchosLogs: Bool) {
        self.watchosLogs = watchosLogs
        getLogs()
    }

    func getWatchOsLogs() {
        if !isLoading {
            isLoading = true
            logs = LoggingHelper(logFile: .watchosLogs).getLogs()?.reversed() ?? []
            isLoading = false
        }
    }
    
    func getLogs() {
        if watchosLogs {
            getWatchOsLogs()
        } else{
            getDeviceLogs()
        }
    }
    
    func getDeviceLogs() {
        if !isLoading {
            isLoading = true
            logs = LoggingHelper().getLogs()?.reversed() ?? []
            isLoading = false
        }
    }
}
