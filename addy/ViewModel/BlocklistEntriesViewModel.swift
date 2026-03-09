//
//  ManageBlocklistViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//

import addy_shared
import Combine
import SwiftUI

// 1. Mark the class as @MainActor to resolve Sendable/Self capture issues
@MainActor
class BlocklistEntriesViewModel: ObservableObject {
    @Published var blocklistEntries: BlocklistEntriesArray? = nil
    @Published var isLoading = false
    @Published var networkError: String = ""

    init() {
        Task {
            await self.getblocklistEntries()
        }
    }

    func getblocklistEntries() async {
        if !isLoading {
            // 2. No more DispatchQueue.main.async needed!
            // @MainActor handles the context switching automatically.
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            do {
                let entries = try await networkHelper.getAllBlocklistEntries()
                self.isLoading = false
                self.blocklistEntries = entries
            } catch {
                self.isLoading = false
                
                // Using your specific localized string format
                self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")
                
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getblocklistEntries",
                    extra: nil
                )
            }
        }
    }
}
