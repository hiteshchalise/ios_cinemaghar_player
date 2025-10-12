//
//  VideoPlayerError.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import Foundation

public enum VideoPlayerError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case playbackError(Error)
    case unsupportedFormat
    case apiError(String)
    case invalidAPIResponse
    case noVideoURLInResponse
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid video URL provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .playbackError(let error):
            return "Playback error: \(error.localizedDescription)"
        case .unsupportedFormat:
            return "Unsupported video format"
        case .apiError(let message):
            return "API error: \(message)"
        case .invalidAPIResponse:
            return "Invalid API response format"
        case .noVideoURLInResponse:
            return "No video URL found in API response"
        }
    }
}
