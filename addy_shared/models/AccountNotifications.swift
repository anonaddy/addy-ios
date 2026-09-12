//
//  AccountNotifications.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2024.
//

import Foundation
#if canImport(SwiftHTMLtoMarkdown)
import SwiftHTMLtoMarkdown
#endif

public struct AccountNotifications: Identifiable, Codable, Sendable {
    public let category: String
    public let created_at: String
    public let id: String
    public let link: String?
    public let link_text: String?
    public let text: String
    public let title: String

    enum CodingKeys: String, CodingKey {
        case category
        case created_at
        case id
        case link
        case link_text
        case text
        case title
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.created_at = try container.decode(String.self, forKey: .created_at)
        self.id = try container.decode(String.self, forKey: .id)
        self.link = try container.decodeIfPresent(String.self, forKey: .link)
        self.link_text = try container.decodeIfPresent(String.self, forKey: .link_text)
        self.text = try container.decode(String.self, forKey: .text)
        self.title = try container.decode(String.self, forKey: .title)
    }

    public init(
        category: String = "",
        created_at: String,
        id: String,
        link: String? = nil,
        link_text: String? = nil,
        text: String,
        title: String
    ) {
        self.category = category
        self.created_at = created_at
        self.id = id
        self.link = link
        self.link_text = link_text
        self.text = text
        self.title = title
    }

    public func textAsMarkdown() -> String {
        #if canImport(SwiftHTMLtoMarkdown)
        do {
            var document = BasicHTML(rawHTML: text)
            try document.parse()
            let markdown = try document.asMarkdown()
            return markdown.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        } catch {
            print("There's an error converting to markdown, return the original text \(error)")
            return text
        }
        #else
        return text
        #endif
    }
}
