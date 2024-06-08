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
                        } else {
                            self.networkError = String(format: String(localized: "details_about_error_s"),"\(error!)")
                            print("Error: \(error)")
                        }
                    }
            })
        }
    }
}
