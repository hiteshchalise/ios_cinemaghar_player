//
//  APIManager.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//


import Foundation

internal final class APIManager {
    private let baseUrl = "https://stg.cinema-ghar.com/"
    
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API
        
    func fetchVideoData(
        userUniqueId: String,
        contentId: Int,
        authToken: String,
        deviceId: String,
        deviceName: String,
        timeout: TimeInterval = 30.0
    ) async throws -> APIResponse {
        let request = try buildRequest(
            userUniqueId: userUniqueId,
            contentId: contentId,
            authToken: authToken,
            deviceId: deviceId,
            deviceName: deviceName,
            timeout: timeout
        )
            
        let (data, response) = try await session.data(for: request)
            
        return try handleResponse(data: data, response: response)
    }
        
    // MARK: - Private Methods
        
    private func buildRequest(
        userUniqueId: String,
        contentId: Int,
        authToken: String,
        deviceId: String,
        deviceName: String,
        timeout: TimeInterval
    ) throws -> URLRequest {
        // Validate and build URL
        guard let url = URL(string: "\(baseUrl)/api/get-url") else {
            throw VideoPlayerError.invalidURL
        }
            
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
            
        // Set headers efficiently
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-VERSION": "1.3",
            "X-DEVICE-TYPE": "setupbox",
            "X-DEVICE-ID": deviceId,
            "X-DEVICE-MODEL": deviceName,
            "Authorization": authToken
        ]
            
        // Encode body
        let body: [String: Any] = [
            "user_unique_id": userUniqueId,
            "payable_type": "content",
            "payable_id": contentId
        ]
            
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw VideoPlayerError.encodingError(error.localizedDescription)
        }
            
        return request
    }
        
    private func handleResponse(
        data: Data,
        response: URLResponse
    ) throws -> APIResponse {
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VideoPlayerError.invalidAPIResponse
        }
            
        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            return try decodeResponse(data: data)
                
        case 401:
            throw VideoPlayerError.unauthorized
                
        case 403:
            throw VideoPlayerError.forbidden
                
        case 404:
            throw VideoPlayerError.notFound
                
        case 500...599:
            let errorMessage = extractErrorMessage(from: data)
            throw VideoPlayerError
                .serverError(httpResponse.statusCode, message: errorMessage)
                
        default:
            let errorMessage = extractErrorMessage(
                from: data
            ) ?? "HTTP \(httpResponse.statusCode)"
            throw VideoPlayerError.apiError(errorMessage)
        }
    }
        
    private func decodeResponse(data: Data) throws -> APIResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
            
        do {
            let apiResponse = try decoder.decode(APIResponse.self, from: data)
                
            // Validate response
            guard apiResponse.isValid else {
                throw VideoPlayerError.invalidResponseData
            }
                
            return apiResponse
        } catch let decodingError as DecodingError {
            // Log detailed decoding errors for debugging
            logDecodingError(decodingError, data: data)
            throw VideoPlayerError
                .decodingError(decodingError.localizedDescription)
        } catch {
            throw VideoPlayerError.decodingError(error.localizedDescription)
        }
    }
        
    private func extractErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
            
        // Try common error message keys
        return json["message"] as? String
        ?? json["error"] as? String
        ?? json["error_description"] as? String
    }
        
    private func logDecodingError(_ error: DecodingError, data: Data) {
#if DEBUG
        print("❌ Decoding Error Details:")
            
        switch error {
        case .keyNotFound(let key, let context):
            print(
                "  Missing key: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))"
            )
                
        case .typeMismatch(let type, let context):
            print(
                "  Type mismatch: Expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))"
            )
                
        case .valueNotFound(let type, let context):
            print(
                "  Value not found: Expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))"
            )
                
        case .dataCorrupted(let context):
            print(
                "  Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))"
            )
                
        @unknown default:
            print("  Unknown decoding error")
        }
            
        // Print raw JSON for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("  Raw JSON: \(jsonString)")
        }
#endif
    }
}
