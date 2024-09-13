//
//  AccountNotificationsViewModel 2.swift
//  addy
//
//  Created by Stijn van de Water on 23/08/2024.
//

import SwiftUI
import Combine
import addy_shared

class AccountNotificationsViewModel: ObservableObject{
    
    @Published var accountNotifications: AccountNotificationsArray? = nil

    @Published var isLoading = false
    @Published var networkError:String = ""
    
    init(){
        Task {
            await self.getAccountNotifications()
        }
    }
    
    func getAccountNotifications() async {
        if !self.isLoading {
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            let networkHelper = NetworkHelper()
            do {
                let accountNotifications = try await networkHelper.getAllAccountNotifications()
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.accountNotifications = accountNotifications
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
