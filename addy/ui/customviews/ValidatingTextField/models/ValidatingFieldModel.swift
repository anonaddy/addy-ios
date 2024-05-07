//
//  FieldModel.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation


protocol FieldValidatorProtocol {
    func validate(value: String)->String?
}

enum FieldType: FieldValidatorProtocol {
    case email
    case url
    case text
    case bigText
        
    func validate(value: String) -> String? {
        switch self {
        case .email:
            return emailValidate(value: value)
        case .url:
            return urlValidate(value: value)
        case .text:
            return nil
        case .bigText:
            return nil
        }
    }
    
    
    private func emailValidate(value:String)->String?
    {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: value) ? nil : String(localized: "not_a_valid_address")
    }
    
    private func urlValidate(value:String)->String?
    {
        return NSPredicate(format: "SELF MATCHES %@", "^(https|http)://.*$").evaluate(with: value) ? nil : String(localized: "not_a_valid_address")
    }
}
