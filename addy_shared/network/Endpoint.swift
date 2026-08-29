//
//  Endpoint.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Supported HTTP request methods.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

/// Declarative representation of an API endpoint and its request properties.
public struct Endpoint {
    /// Target URL string for the request.
    public var urlString: String
    /// HTTP method (GET, POST, PATCH, PUT, DELETE).
    public var method: HTTPMethod
    /// Optional URL query items.
    public var queryItems: [URLQueryItem]?
    /// Optional HTTP request body data.
    public var body: Data?
    /// Optional custom HTTP headers to merge into the request.
    public var customHeaders: [String: String]?
    /// Optional API key override (bypasses saved settings).
    public var apiKeyOverride: String?

    public init(
        urlString: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil,
        customHeaders: [String: String]? = nil,
        apiKeyOverride: String? = nil
    ) {
        self.urlString = urlString
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.customHeaders = customHeaders
        self.apiKeyOverride = apiKeyOverride
    }

    public func urlRequest(defaultHeaders: [String: String]) throws -> URLRequest {
        guard var components = URLComponents(string: urlString) else {
            throw NetworkError.invalidURL
        }

        if let queryItems = queryItems, !queryItems.isEmpty {
            var existingItems = components.queryItems ?? []
            existingItems.append(contentsOf: queryItems)
            components.queryItems = existingItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = defaultHeaders

        if let customHeaders = customHeaders {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        if let body = body {
            request.httpBody = body
        }

        return request
    }
}
