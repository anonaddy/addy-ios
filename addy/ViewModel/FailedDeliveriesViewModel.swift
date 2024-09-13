//
//  FailedDeliveriesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import SwiftUI
import Combine
import addy_shared

class FailedDeliveriesViewModel: ObservableObject{
    
    @Published var failedDeliveries: FailedDeliveriesArray? = nil

    @Published var isLoading = false
    @Published var networkError:String = ""
    
    init(){
        Task {
            await self.getFailedDeliveries()
        }
    }
    
    func getFailedDeliveries() async {
        if !self.isLoading {
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            let networkHelper = NetworkHelper()
            do {
                let failedDeliveries = try await networkHelper.getFailedDeliveries()
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.failedDeliveries = failedDeliveries
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
