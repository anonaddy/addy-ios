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
        self.getFailedDeliveries()
    }
    
    func getFailedDeliveries(){
        if (!self.isLoading){
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            networkHelper.getFailedDeliveries(completion: { failedDeliveries, error in
                    DispatchQueue.main.async {
                        self.isLoading = false

                        if let failedDeliveries = failedDeliveries {
                            self.failedDeliveries = failedDeliveries
                            
                            // Set the count of failed deliveries so that we can use it for the backgroundservice AND mark this a read for the badge
                            MainViewState.shared.encryptedSettingsManager.putSettingsInt(
                                key: .backgroundServiceCacheFailedDeliveriesCount,
                                int: failedDeliveries.data.count
                            )
                        } else {
                            self.networkError = String(format: String(localized: "details_about_error_s"),"\(error!)")
                        }
                    }
            })
        }
    }
}
