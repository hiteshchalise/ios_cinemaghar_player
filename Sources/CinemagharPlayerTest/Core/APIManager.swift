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
        print("🚀 [START] fetchVideoData called")
        print("📋 Parameters:")
        print("  - userUniqueId: \(userUniqueId)")
        print("  - contentId: \(contentId)")
        print("  - authToken: \(authToken.prefix(20))... (truncated)")
        print("  - deviceId: \(deviceId)")
        print("  - deviceName: \(deviceName)")
        print("  - timeout: \(timeout)s")
        
        do {
            print("\n🔨 Building request...")
            let request = try buildRequest(
                userUniqueId: userUniqueId,
                contentId: contentId,
                authToken: authToken,
                deviceId: deviceId,
                deviceName: deviceName,
                timeout: timeout
            )
            print("✅ Request built successfully")
            
            print("\n📡 Making network call...")
            print("  URL: \(request.url?.absoluteString ?? "nil")")
            print("  Method: \(request.httpMethod ?? "nil")")
            print("  Timeout: \(request.timeoutInterval)s")
            
            let (data, response) = try await session.data(for: request)
            
            print("\n✅ Network call completed")
            print("  Data size: \(data.count) bytes")
            print("  Response type: \(type(of: response))")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("  Status code: \(httpResponse.statusCode)")
                print("  Headers: \(httpResponse.allHeaderFields)")
            }
            
            print("\n🔍 Handling response...")
            let result = try handleResponse(data: data, response: response)
            print("✅ Response handled successfully")
            print("🏁 [END] fetchVideoData completed successfully\n")
            
            return result
            
        } catch {
            print("\n❌ [ERROR] fetchVideoData failed")
            print("  Error: \(error)")
            print("  Error type: \(type(of: error))")
            print("🏁 [END] fetchVideoData completed with error\n")
            throw error
        }
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
        print("  🔗 Building URL...")
        // Validate and build URL
        guard let url = URL(string: "\(baseUrl)/api/get-url") else {
            print("  ❌ Invalid URL: \(baseUrl)/api/get-url")
            throw VideoPlayerError.invalidURL
        }
        print("  ✅ URL created: \(url.absoluteString)")
        
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        
        print("  📝 Setting headers...")
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
        print("  ✅ Headers set: \(request.allHTTPHeaderFields?.keys.joined(separator: ", ") ?? "none")")
        
        print("  📦 Encoding body...")
        // Encode body
        let body: [String: Any] = [
            "user_unique_id": userUniqueId,
            "payable_type": "content",
            "payable_id": contentId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("  ✅ Body encoded: \(bodyString)")
            }
        } catch {
            print("  ❌ Body encoding failed: \(error)")
            throw VideoPlayerError.encodingError(error.localizedDescription)
        }
        
        return request
    }
        
    private func handleResponse(
        data: Data,
        response: URLResponse
    ) throws -> APIResponse {
        print("  🔍 Validating HTTP response...")
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("  ❌ Response is not HTTPURLResponse")
            throw VideoPlayerError.invalidAPIResponse
        }
        
        print("  ✅ HTTP Response received")
        print("    Status: \(httpResponse.statusCode)")
        print("    URL: \(httpResponse.url?.absoluteString ?? "nil")")
        
        // Print raw response data
        if let jsonString = String(data: data, encoding: .utf8) {
            print("    Raw response: \(jsonString)")
        } else {
            print("    Raw response: Unable to convert data to string")
        }
        
        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            print("  ✅ Success status code, decoding...")
            return try decodeResponse(data: data)
                
        case 401:
            print("  ❌ Unauthorized (401)")
            throw VideoPlayerError.unauthorized
                
        case 403:
            print("  ❌ Forbidden (403)")
            throw VideoPlayerError.forbidden
                
        case 404:
            print("  ❌ Not Found (404)")
            throw VideoPlayerError.notFound
                
        case 500...599:
            let errorMessage = extractErrorMessage(from: data)
            print("  ❌ Server Error (\(httpResponse.statusCode)): \(errorMessage ?? "No message")")
            throw VideoPlayerError
                .serverError(httpResponse.statusCode, message: errorMessage)
                
        default:
            let errorMessage = extractErrorMessage(
                from: data
            ) ?? "HTTP \(httpResponse.statusCode)"
            print("  ❌ API Error: \(errorMessage)")
            throw VideoPlayerError.apiError(errorMessage)
        }
    }
        
    private func decodeResponse(data: Data) throws -> APIResponse {
        print("    🔓 Decoding response...")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let apiResponse = try decoder.decode(APIResponse.self, from: data)
            print("    ✅ Response decoded successfully")
            
            // Validate response
            guard apiResponse.isValid else {
                print("    ❌ Response validation failed")
                throw VideoPlayerError.invalidResponseData
            }
            
            print("    ✅ Response validated successfully")
            return apiResponse
            
        } catch let decodingError as DecodingError {
            print("    ❌ Decoding error occurred")
            // Log detailed decoding errors for debugging
            logDecodingError(decodingError, data: data)
            throw VideoPlayerError
                .decodingError(decodingError.localizedDescription)
        } catch {
            print("    ❌ Unknown decoding error: \(error)")
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
