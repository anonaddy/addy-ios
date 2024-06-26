//
//  UsernamesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import SwiftUI
import Combine
import addy_shared

class UsernamesViewModel: ObservableObject{
    
    @Published var usernames: UsernamesArray? = nil

    @Published var isLoading = false
    @Published var networkError:String = ""
    
    init(){
        Task {
            await self.getUsernames()
        }
    }
    
    func getUsernames() async {
        if !self.isLoading {
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            let networkHelper = NetworkHelper()
            do {
                let usernames = try await networkHelper.getUsernames()
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.usernames = usernames
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
