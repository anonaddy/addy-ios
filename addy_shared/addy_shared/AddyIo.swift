//
//  AddyIo.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

public struct AddyIo {
    public static var API_BASE_URL = "https://app.addy.io"

    // The versioncode is a combination of MAJOR MINOR PATCH
    //TODO: Update on every release

    // 1.2.3
    public static let MINIMUMVERSIONCODEMAJOR = 1
    public static let MINIMUMVERSIONCODEMINOR = 2
    public static let MINIMUMVERSIONCODEPATCH = 3

    public static var VERSIONMAJOR = 0
    public static var VERSIONMINOR = 0
    public static var VERSIONPATCH = 0
    public static var VERSIONSTRING = ""

    // API endpoints
    static var API_URL_RECIPIENTS: String { "\(API_BASE_URL)/api/v1/recipients" }
    static var API_URL_ALLOWED_RECIPIENTS: String { "\(API_BASE_URL)/api/v1/allowed-recipients" }
    static var API_URL_ALIAS: String { "\(API_BASE_URL)/api/v1/aliases" }
    static var API_URL_ACTIVE_ALIAS: String { "\(API_BASE_URL)/api/v1/active-aliases" }
    static var API_URL_ALIAS_RECIPIENTS: String { "\(API_BASE_URL)/api/v1/alias-recipients" }
    static var API_URL_DOMAIN_OPTIONS: String { "\(API_BASE_URL)/api/v1/domain-options" }
    static var API_URL_ENCRYPTED_RECIPIENTS: String { "\(API_BASE_URL)/api/v1/encrypted-recipients" }
    static var API_URL_INLINE_ENCRYPTED_RECIPIENTS: String { "\(API_BASE_URL)/api/v1/inline-encrypted-recipients" }
    static var API_URL_PROTECTED_HEADERS_RECIPIENTS: String { "\(API_BASE_URL)/api/v1/protected-headers-recipients" }
    static var API_URL_RECIPIENT_RESEND: String { "\(API_BASE_URL)/api/v1/recipients/email/resend" }
    static var API_URL_RECIPIENT_KEYS: String { "\(API_BASE_URL)/api/v1/recipient-keys" }
    static var API_URL_ACCOUNT_DETAILS: String { "\(API_BASE_URL)/api/v1/account-details" }
    static var API_URL_DOMAINS: String { "\(API_BASE_URL)/api/v1/domains" }
    static var API_URL_ACTIVE_DOMAINS: String { "\(API_BASE_URL)/api/v1/active-domains" }
    static var API_URL_CATCH_ALL_DOMAINS: String { "\(API_BASE_URL)/api/v1/catch-all-domains" }
    static var API_URL_USERNAMES: String { "\(API_BASE_URL)/api/v1/usernames" }
    static var API_URL_ACTIVE_USERNAMES: String { "\(API_BASE_URL)/api/v1/active-usernames" }
    static var API_URL_CATCH_ALL_USERNAMES: String { "\(API_BASE_URL)/api/v1/catch-all-usernames" }
    static var API_URL_CAN_LOGIN_USERNAMES: String { "\(API_BASE_URL)/api/v1/loginable-usernames" }
    static var API_URL_RULES: String { "\(API_BASE_URL)/api/v1/rules" }
    static var API_URL_ACTIVE_RULES: String { "\(API_BASE_URL)/api/v1/active-rules" }
    static var API_URL_REORDER_RULES: String { "\(API_BASE_URL)/api/v1/reorder-rules" }
    static var API_URL_API_TOKEN_DETAILS: String { "\(API_BASE_URL)/api/v1/api-token-details" }
    static var API_URL_FAILED_DELIVERIES: String { "\(API_BASE_URL)/api/v1/failed-deliveries" }
    static var API_URL_APP_VERSION: String { "\(API_BASE_URL)/api/v1/app-version" }
    static var API_URL_CHART_DATA: String { "\(API_BASE_URL)/api/v1/chart-data" }

    // Github built-in updater
    static let GITHUB_TAGS_RSS_FEED = "https://github.com/anonaddy/addy-ios/releases.atom"
    
    
    // Hosted only
    static var API_URL_ACCOUNT_NOTIFICATIONS: String { "\(API_BASE_URL)/api/v1/account-notifications" }
}
