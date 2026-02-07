//
//  SharedHelper.swift
//  addy
//
//  Created by Stijn van de Water on 07/02/2026.
//

import Foundation

public enum SharedLocalization {
    /// Bundle for the shared target (framework/module)
    private static let bundle: Bundle = {
        // If it's a Swift Package:
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()

    private final class BundleToken {}

    static func localized(_ key: String,
                          table: String? = nil,
                          value: String = "") -> String {
        NSLocalizedString(
            key,
            tableName: table,
            bundle: bundle,
            value: value,
            comment: ""
        )
    }
}
