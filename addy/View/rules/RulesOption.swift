//
//  RulesOption.swift
//  addy
//
//  Created by Stijn van de Water on 06/06/2024.
//

import Foundation

enum RulesOption {
    static let bannerLocationOptions = ["top", "bottom", "off"]
    static let bannerLocationOptionName = [
        NSLocalizedString("rule_bannerlocation_top", comment: ""),
        NSLocalizedString("rule_bannerlocation_bottom", comment: ""),
        NSLocalizedString("rule_bannerlocation_off", comment: ""),
    ]

    static let conditionsType = [
        "sender",
        "subject",
        "alias",
        "alias_description",
        "alias_label",
        "display_from",
        "header",
        "alias_created_by_catch_all",
        "alias_not_created_by_catch_all",
        "has_attachments",
        "has_no_attachments",
        "email_is_spam",
        "email_is_not_spam",
        "dmarc_failed",
        "dmarc_did_not_fail",
        "email_size",
        "alias_emails_forwarded",
    ]
    static let conditionsTypeName = [
        NSLocalizedString("the_sender", comment: ""),
        NSLocalizedString("the_subject", comment: ""),
        NSLocalizedString("the_alias", comment: ""),
        NSLocalizedString("the_alias_description", comment: ""),
        NSLocalizedString("the_alias_label", comment: ""),
        NSLocalizedString("the_display_from", comment: ""),
        NSLocalizedString("the_header", comment: ""),
        NSLocalizedString("alias_created_by_catch_all", comment: ""),
        NSLocalizedString("alias_not_created_by_catch_all", comment: ""),
        NSLocalizedString("has_attachments", comment: ""),
        NSLocalizedString("has_no_attachments", comment: ""),
        NSLocalizedString("email_is_spam", comment: ""),
        NSLocalizedString("email_is_not_spam", comment: ""),
        NSLocalizedString("dmarc_failed", comment: ""),
        NSLocalizedString("dmarc_did_not_fail", comment: ""),
        NSLocalizedString("the_email_size", comment: ""),
        NSLocalizedString("alias_emails_forwarded", comment: ""),
    ]

    static let stringConditionsMatch = [
        "contains",
        "does not contain",
        "is exactly",
        "is not",
        "starts with",
        "does not start with",
        "ends with",
        "does not end with",
        "matches regex",
        "does not match regex",
    ]
    static let stringConditionsMatchName = [
        NSLocalizedString("contains", comment: ""),
        NSLocalizedString("does_not_contain", comment: ""),
        NSLocalizedString("is_exactly", comment: ""),
        NSLocalizedString("is_not", comment: ""),
        NSLocalizedString("starts_with", comment: ""),
        NSLocalizedString("does_not_start_with", comment: ""),
        NSLocalizedString("ends_with", comment: ""),
        NSLocalizedString("does_not_end_with", comment: ""),
        NSLocalizedString("matches_regex", comment: ""),
        NSLocalizedString("does_not_match_regex", comment: ""),
    ]

    static let headerConditionsMatch = [
        "exists",
        "does not exist",
    ]
    static let headerConditionsMatchName = [
        NSLocalizedString("rule_match_exists", comment: ""),
        NSLocalizedString("rule_match_does_not_exist", comment: ""),
    ]

    static let numericConditionsMatch = [
        "is exactly",
        "is not",
        "is greater than",
        "is less than",
    ]
    static let numericConditionsMatchName = [
        NSLocalizedString("is_exactly", comment: ""),
        NSLocalizedString("is_not", comment: ""),
        NSLocalizedString("rule_match_is_greater_than", comment: ""),
        NSLocalizedString("rule_match_is_less_than", comment: ""),
    ]

    static let conditionsMatch = [
        "contains",
        "does not contain",
        "is exactly",
        "is not",
        "starts with",
        "does not start with",
        "ends with",
        "does not end with",
        "matches regex",
        "does not match regex",
        "exists",
        "does not exist",
        "is greater than",
        "is less than",
    ]
    static let conditionsMatchName = [
        NSLocalizedString("contains", comment: ""),
        NSLocalizedString("does_not_contain", comment: ""),
        NSLocalizedString("is_exactly", comment: ""),
        NSLocalizedString("is_not", comment: ""),
        NSLocalizedString("starts_with", comment: ""),
        NSLocalizedString("does_not_start_with", comment: ""),
        NSLocalizedString("ends_with", comment: ""),
        NSLocalizedString("does_not_end_with", comment: ""),
        NSLocalizedString("matches_regex", comment: ""),
        NSLocalizedString("does_not_match_regex", comment: ""),
        NSLocalizedString("rule_match_exists", comment: ""),
        NSLocalizedString("rule_match_does_not_exist", comment: ""),
        NSLocalizedString("rule_match_is_greater_than", comment: ""),
        NSLocalizedString("rule_match_is_less_than", comment: ""),
    ]

    static let actionsType = [
        "subject",
        "displayFrom",
        "encryption",
        "banner",
        "block",
        "blocklistSender",
        "blocklistDomain",
        "removeAttachments",
        "forwardTo",
        "addLabel",
        "removeLabel",
        "setAliasDescription",
        "deactivateAlias",
        "deleteAlias",
    ]
    static let actionsTypeName = [
        NSLocalizedString("replace_the_subject_with", comment: ""),
        NSLocalizedString("replace_the_from_name_with", comment: ""),
        NSLocalizedString("turn_PGP_encryption_off", comment: ""),
        NSLocalizedString("set_the_banner_information_location_to", comment: ""),
        NSLocalizedString("block_the_email", comment: ""),
        NSLocalizedString("add_sender_to_blocklist", comment: ""),
        NSLocalizedString("add_domain_to_blocklist", comment: ""),
        NSLocalizedString("remove_attachments", comment: ""),
        NSLocalizedString("forward_to", comment: ""),
        NSLocalizedString("add_label_action", comment: ""),
        NSLocalizedString("remove_label_action", comment: ""),
        NSLocalizedString("set_alias_description_action", comment: ""),
        NSLocalizedString("deactivate_alias_action", comment: ""),
        NSLocalizedString("delete_alias_action", comment: ""),
    ]

    static func isBooleanCondition(type: String) -> Bool {
        return [
            "alias_created_by_catch_all",
            "alias_not_created_by_catch_all",
            "has_attachments",
            "has_no_attachments",
            "email_is_spam",
            "email_is_not_spam",
            "dmarc_failed",
            "dmarc_did_not_fail",
        ].contains(type)
    }

    static func isHeaderCondition(type: String) -> Bool {
        return type == "header"
    }

    static func isNumericCondition(type: String) -> Bool {
        return ["email_size", "alias_emails_forwarded"].contains(type)
    }

    static func isBooleanAction(type: String) -> Bool {
        return [
            "encryption",
            "block",
            "blocklistSender",
            "blocklistDomain",
            "removeAttachments",
            "deactivateAlias",
            "deleteAlias",
        ].contains(type)
    }

    static func isTextAction(type: String) -> Bool {
        return [
            "subject",
            "displayFrom",
            "setAliasDescription",
        ].contains(type)
    }

    static func isLabelAction(type: String) -> Bool {
        return [
            "addLabel",
            "removeLabel",
        ].contains(type)
    }

    static func matches(for conditionType: String) -> [String] {
        if isHeaderCondition(type: conditionType) {
            return headerConditionsMatch
        } else if isNumericCondition(type: conditionType) {
            return numericConditionsMatch
        } else if isBooleanCondition(type: conditionType) {
            return []
        } else {
            return stringConditionsMatch
        }
    }

    static func matchNames(for conditionType: String) -> [String] {
        if isHeaderCondition(type: conditionType) {
            return headerConditionsMatchName
        } else if isNumericCondition(type: conditionType) {
            return numericConditionsMatchName
        } else if isBooleanCondition(type: conditionType) {
            return []
        } else {
            return stringConditionsMatchName
        }
    }

    static func conditionTypeName(for type: String) -> String {
        guard let index = conditionsType.firstIndex(of: type) else { return type }
        return conditionsTypeName[index]
    }

    static func matchName(for match: String) -> String {
        guard let index = conditionsMatch.firstIndex(of: match) else { return match }
        return conditionsMatchName[index]
    }

    static func actionTypeName(for type: String) -> String {
        guard let index = actionsType.firstIndex(of: type) else { return type }
        return actionsTypeName[index]
    }
}
