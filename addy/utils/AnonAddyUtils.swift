//
//  AddyUtils.swift
//  addy
//
//  Created by Stijn van de Water on 20/05/2024.
//

import Foundation
import SwiftUI
import addy_shared

class AnonAddyUtils {
    static func getSendAddress(recipientEmails: [String], alias: Aliases) -> [String] {
        var toAddresses = [String]()

        for (_, email) in recipientEmails.enumerated() {
            let leftPartOfAlias = alias.local_part
            let domain = alias.domain
            let recipientLeftPartOfEmail = email.components(separatedBy: "@").first ?? ""
            let recipientRightPartOfEmail = email.components(separatedBy: "@").last ?? ""
            toAddresses.append("\(leftPartOfAlias)+\(recipientLeftPartOfEmail)=\(recipientRightPartOfEmail)@\(domain)")
        }
        
        return toAddresses
    }
}
