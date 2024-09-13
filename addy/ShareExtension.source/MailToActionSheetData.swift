//
//  MailToActionSheetData.swift
//  addy
//
//  Created by Stijn van de Water on 01/07/2024.
//

import Foundation

struct MailToActionSheetData: Identifiable {
    let id = UUID()
    let value: String

    init(value: String) {
        self.value = value
    }
}
