//
//  VideoPlayerError.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import Foundation


enum VideoPlayerError: LocalizedError, Sendable {
    case invalidURL
    case encodingError(String)
    case networkError(String)
    case playbackError(Error)
    case unsupportedFormat
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int, message: String?)
    case apiError(String)
    case invalidAPIResponse
    case decodingError(String)
    case invalidResponseData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
            
        case .encodingError(let message):
            return "Failed to encode request: \(message)"
            
        case .networkError(let message):
            return "Network error: \(message)"
            
        case .unauthorized:
            return "Unauthorized - Please log in again"
            
        case .forbidden:
            return "Access forbidden - Insufficient permissions"
            
        case .notFound:
            return "Content not found"
            
        case .serverError(let code, let message):
            if let message = message {
                return "Server error (HTTP \(code)): \(message)"
            }
            return "Server error (HTTP \(code))"
            
        case .apiError(let message):
            return "API error: \(message)"
            
        case .invalidAPIResponse:
            return "Invalid API response format"
            
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
            
        case .invalidResponseData:
            return "Response missing required data"
            
        case .playbackError(let error):
            return "Playback error: \(error.localizedDescription)"

        case .unsupportedFormat:
            return "Unsupported video format"
        }
    }
    
    var isRetriable: Bool {
        switch self {
        case .networkError, .serverError:
            return true
        default:
            return false
        }
    }
}
