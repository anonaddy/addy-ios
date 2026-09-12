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

    /// Robust asynchronous check that resolves DNS if the fast string check returns false.
    public static func isLocalAddressRobust(_ urlString: String) async -> Bool {
        // Fast path
        if isLocalAddress(urlString) {
            return true
        }

        guard let host = extractHost(from: urlString) else {
            return false
        }

        // Slow path: DNS resolution
        return await Task.detached {
            var hints = addrinfo(
                ai_flags: AI_ADDRCONFIG,
                ai_family: AF_UNSPEC,
                ai_socktype: SOCK_STREAM,
                ai_protocol: 0,
                ai_addrlen: 0,
                ai_canonname: nil,
                ai_addr: nil,
                ai_next: nil
            )
            var res: UnsafeMutablePointer<addrinfo>?
            guard getaddrinfo(host, nil, &hints, &res) == 0, let first = res else {
                return false
            }
            defer { freeaddrinfo(res) }

            var ptr: UnsafeMutablePointer<addrinfo>? = first
            while let current = ptr {
                if current.pointee.ai_family == AF_INET {
                    let addr = current.pointee.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                    let ip = UInt32(bigEndian: addr.sin_addr.s_addr)
                    // 10.0.0.0/8
                    if (ip & 0xFF000000) == 0x0A000000 { return true }
                    // 172.16.0.0/12 (172.16.0.0 to 172.31.255.255)
                    if (ip & 0xFFF00000) == 0xAC100000 { return true }
                    // 192.168.0.0/16
                    if (ip & 0xFFFF0000) == 0xC0A80000 { return true }
                    // 127.0.0.0/8
                    if (ip & 0xFF000000) == 0x7F000000 { return true }
                    // 169.254.0.0/16
                    if (ip & 0xFFFF0000) == 0xA9FE0000 { return true }
                } else if current.pointee.ai_family == AF_INET6 {
                    let addr = current.pointee.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
                    let bytes = addr.sin6_addr.__u6_addr.__u6_addr8
                    // Loopback ::1
                    let isLoopback = bytes.0 == 0 && bytes.1 == 0 && bytes.2 == 0 && bytes.3 == 0 &&
                                     bytes.4 == 0 && bytes.5 == 0 && bytes.6 == 0 && bytes.7 == 0 &&
                                     bytes.8 == 0 && bytes.9 == 0 && bytes.10 == 0 && bytes.11 == 0 &&
                                     bytes.12 == 0 && bytes.13 == 0 && bytes.14 == 0 && bytes.15 == 1
                    if isLoopback { return true }
                    // ULA fc00::/7 (fc00... or fd00...)
                    let firstByte = bytes.0
                    if (firstByte & 0xFE) == 0xFC { return true }
                    // Link-local fe80::/10 (fe80... to febf...)
                    if firstByte == 0xFE && (bytes.1 & 0xC0) == 0x80 { return true }
                }
                ptr = current.pointee.ai_next
            }
            return false
        }.value
    }
}
