//
//  ManageBlocklistViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//

import addy_shared
import Combine
import SwiftUI

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
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            let networkHelper = NetworkHelper()
            do {
                let blocklistEntries = try await networkHelper.getAllBlocklistEntries()
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.blocklistEntries = blocklistEntries
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")
                }
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getblocklistEntrys", extra: nil
                )
            }
        }
    }
}
