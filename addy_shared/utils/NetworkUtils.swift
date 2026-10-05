//
//  NetworkUtils.swift
//  addy_shared
//
//  Created by Antigravity on 12/09/2026.
//

import Foundation

public enum NetworkUtils {
    
    /// Extracts the host string from a URL or raw IP/hostname string.
    public static func extractHost(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        // If string does not contain scheme, prepend http:// to parse with URL / URLComponents
        let formatted = trimmed.contains("://") ? trimmed : "http://\(trimmed)"
        guard let url = URL(string: formatted), let host = url.host else {
            return nil
        }

        var cleanHost = host
        // Strip brackets for IPv6 if present
        if cleanHost.hasPrefix("[") && cleanHost.hasSuffix("]") {
            cleanHost = String(cleanHost.dropFirst().dropLast())
        }
        return cleanHost.lowercased()
    }

    /// Fast, synchronous check to determine if an address is on the local network.
    public static func isLocalAddress(_ urlString: String) -> Bool {
        guard let host = extractHost(from: urlString) else {
            return false
        }

        // Common local hostnames
        if host == "localhost" || host.hasSuffix(".local") {
            return true
        }

        // Unqualified hostnames (no dots, no colons) are typically local network hosts (e.g. "pi-hole", "nas")
        if !host.contains(".") && !host.contains(":") {
            return true
        }

        // IPv4 private ranges & loopback:
        // 10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12, 127.0.0.0/8, 169.254.0.0/16
        let ipv4Regex = #"^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|127\.|169\.254\.)"#
        if host.range(of: ipv4Regex, options: .regularExpression) != nil {
            return true
        }

        // IPv6 local ranges:
        // fc00::/7 (Unique Local Address, fc00: or fd00:)
        // fe80::/10 (Link-Local)
        // ::1 (Loopback)
        if host.hasPrefix("fc00:") || host.hasPrefix("fd00:") || host.hasPrefix("fe80:") || host == "::1" {
            return true
        }

        return false
    }
}
