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
        self.getUsernames()
    }
    
    func getUsernames(){
        if (!self.isLoading){
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            networkHelper.getUsernames(completion: { usernames, error in
                    DispatchQueue.main.async {
                        self.isLoading = false

                        if let usernames = usernames {
                            self.usernames = usernames
                        } else {
                            self.networkError = String(format: String(localized: "details_about_error_s"),"\(error)")
                            print("Error: \(error)")
                        }
                    }
            })
        }
    }
}
