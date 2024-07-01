//
//  MailToActionSheetData.swift
//  addy
//
//  Created by Stijn van de Water on 01/07/2024.
//

import Foundation

public struct MailToActionSheetData: Identifiable {
    public let id = UUID()
    public let value: String

    public init(value: String) {
        self.value = value
    }
}
