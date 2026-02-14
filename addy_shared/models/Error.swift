//
//  Error.swift
//  addy_shared
//
//  Created by Stijn van de Water on 08/05/2024.
//

import Foundation

struct Error: Codable {
    let message: String
}

class ErrorHelper {
    // Try to extract message from error. if fails return full json
    static func getErrorMessage(data: Data) -> String {
        do {
            let decoder = JSONDecoder()
            let errorData = try decoder.decode(Error.self, from: data)
            return errorData.message
        } catch {
            return String(data: data, encoding: .utf8) ?? "Error decoding data"
        }
    }
}
