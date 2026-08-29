//
//  NetworkError.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Represents strongly-typed network and API errors thrown across domain repositories.
public enum NetworkError: LocalizedError, Equatable {
    /// The requested URL is malformed or invalid.
    case invalidURL
    /// Authentication failed (401 Unauthorized or missing API token).
    case unauthorized(message: String)
    /// Server rejected entity data (422 Unprocessable Entity, e.g. validation failure).
    case unprocessableEntity(message: String)
    /// Access denied (403 Forbidden).
    case forbidden(message: String)
    /// Resource not found (404 Not Found).
    case notFound(message: String)
    /// Generic HTTP error with an HTTP status code and message.
    case httpError(statusCode: Int, message: String)
    /// Response JSON decoding failed.
    case decodingError(message: String)
    /// Low-level transport or connectivity failure.
    case transportError(message: String)
    /// Unspecified error.
    case unknown(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error_invalid_url", bundle: Bundle(for: SharedData.self), comment: "Invalid URL")
        case .unauthorized(let message):
            return message.isEmpty ? NSLocalizedString("error_unauthorized", bundle: Bundle(for: SharedData.self), comment: "Unauthorized") : message
        case .unprocessableEntity(let message),
             .forbidden(let message),
             .notFound(let message),
             .httpError(_, let message),
             .decodingError(let message),
             .transportError(let message),
             .unknown(let message):
            return message
        }
    }
}
