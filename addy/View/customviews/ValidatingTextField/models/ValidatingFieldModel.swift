//
//  ValidatingFieldModel.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation
import UIKit

enum FieldType {
    case email
    case commaSeparatedEmails
    case url
    case text
    case numeric
    case otp
    case bigText
    case password
    case domain

    func validate(value: String) -> String? {
        switch self {
        case .email:
            return emailValidate(value: value)
        case .commaSeparatedEmails:
            return commaSeparatedEmails(value: value)
        case .url:
            return urlValidate(value: value)
        case .text:
            return nil
        case .numeric:
            return numberValidate(value: value)
        case .otp:
            return numberValidate(value: value, length: 6)
        case .bigText:
            return nil
        case .password:
            return nil
        case .domain:
            return domainValidate(value: value)
        }
    }

    func getKeyboardType() -> UIKeyboardType {
        switch self {
        case .email:
            return UIKeyboardType.default // Not UIKeyboardType.emailAddress as it won't have the option to comma separate
        case .commaSeparatedEmails:
            return UIKeyboardType.default // Not UIKeyboardType.emailAddress as it won't have the option to comma separate
        case .url:
            return UIKeyboardType.URL
        case .text:
            return UIKeyboardType.default
        case .numeric:
            return UIKeyboardType.numberPad
        case .otp:
            return UIKeyboardType.numberPad
        case .bigText:
            return UIKeyboardType.default
        case .password:
            return UIKeyboardType.default
        case .domain:
            return UIKeyboardType.URL
        }
    }

    private func emailValidate(value: String) -> String? {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: value.trimmingCharacters(in: .whitespaces)) ? nil : String(localized: "not_a_valid_address")
    }

    private func numberValidate(value: String, length: Int? = nil) -> String? {
        if let length {
            if value.count != length {
                return String(localized: "otp_not_the_right_length")
            }
        }

        let digitsOnlyRegex = "^[0-9]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", digitsOnlyRegex)
        return predicate.evaluate(with: value) ? nil : String(localized: "only_use_numbers")
    }

    private func domainValidate(value: String) -> String? {
        let domainRegEx = "([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}"
        let domainPred = NSPredicate(format: "SELF MATCHES %@", domainRegEx)
        return domainPred.evaluate(with: value.trimmingCharacters(in: .whitespaces)) ? nil : String(localized: "not_a_valid_address")
    }

    private func commaSeparatedEmails(value: String) -> String? {
        let emails = value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        guard !emails.isEmpty else {
            return String(localized: "not_a_valid_address")
        }

        for email in emails {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)

            if !emailPred.evaluate(with: email) {
                return String(localized: "not_a_valid_address")
            }
        }

        return nil
    }

    private func urlValidate(value: String) -> String? {
        return NSPredicate(format: "SELF MATCHES %@", "^(https|http)://.*$").evaluate(with: value.trimmingCharacters(in: .whitespaces)) ? nil : String(localized: "not_a_valid_address")
    }
}
