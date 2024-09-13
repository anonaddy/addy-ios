//
//  LogsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 11/06/2024.
//

import SwiftUI
import Combine
import addy_shared

class LogsViewModel: ObservableObject{
    
    @Published var logs: [Logs]? = nil

    @Published var isLoading = false
    
    init(){
        self.getLogs()
    }
    
    func getLogs(){
        if (!self.isLoading){
            self.isLoading = true
            self.logs = LoggingHelper().getLogs()?.reversed() ?? []
            self.isLoading = false
        }
    }
}
