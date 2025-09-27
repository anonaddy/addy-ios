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

    init() {
        getLogs()
    }

    func getLogs() {
        if !isLoading {
            isLoading = true
            logs = LoggingHelper().getLogs()?.reversed() ?? []
            isLoading = false
        }
    }
}
