//
//  AccountNotifications.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2024.
//

import Foundation
import SwiftHTMLtoMarkdown


public struct AccountNotificationsArray: Codable {
    public let data: [AccountNotifications]
}

public struct AccountNotifications: Identifiable, Codable {
    let category: String
    public let created_at: String
    public let id: String
    public let link: String?
    public let link_text: String?
    public let text: String
    public let title: String
    
    public func textAsMarkdown() -> String {
        do {
            var document = BasicHTML(rawHTML: text)
            try document.parse()
            let markdown = try document.asMarkdown()
            return markdown.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        } catch {
            print("There's an error converting to markdown, return the original text \(error)")
            return text
        }
    }
}
