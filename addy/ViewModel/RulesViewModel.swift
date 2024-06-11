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

    @Published var isLoading = false
    @Published var networkError:String = ""
    
    init(){
        self.getRules()
    }
    
    func getRules(){
        if (!self.isLoading){
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            networkHelper.getRules(completion: { rules, error in
                    DispatchQueue.main.async {
                        self.isLoading = false

                        if let rules = rules {
                            self.rules = rules
                        } else {
                            self.networkError = String(format: String(localized: "details_about_error_s"),"\(error!)")
                        }
                    }
            })
        }
    }
}
