//
//  APIManager.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//


import Foundation

internal class APIManager {
    private let session = URLSession.shared
    
    func fetchVideoData(from endpoint: String, 
                       headers: [String: String] = [:],
                       timeout: TimeInterval = 30.0,
                       completion: @escaping (Result<APIResponse, VideoPlayerError>) -> Void) {
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        
        // Add headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.invalidAPIResponse))
                    return
                }
                
                // Check HTTP status code
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    completion(.failure(.apiError("HTTP \(httpResponse.statusCode)")))
                    return
                }
                
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(.invalidAPIResponse))
                }
            }
        }.resume()
    }
}
