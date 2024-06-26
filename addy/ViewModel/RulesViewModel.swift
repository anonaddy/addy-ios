//
//  RulesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import SwiftUI
import Combine
import addy_shared

class RulesViewModel: ObservableObject{
    
    @Published var rules: RulesArray? = nil
    @Published var recipients: [Recipients] = []

    @Published var isLoading = false
    @Published var networkError:String = ""
    
    init() {
        Task{
            await self.getRules()
        }
    }
    
    func getRules() async {
        if !self.isLoading {
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            let networkHelper = NetworkHelper()
            do {
                if let recipients = try await networkHelper.getRecipients(verifiedOnly: false){
                    let rules = try await networkHelper.getRules()
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.rules = rules
                        self.recipients = recipients
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.networkError = String(format: String(localized: "details_about_error_s"), "\(error.localizedDescription)")
                }
            }
        }
    }


}
