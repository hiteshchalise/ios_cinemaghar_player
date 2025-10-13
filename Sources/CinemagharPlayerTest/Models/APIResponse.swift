//
//  APIResponse.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import Foundation

public struct APIResponse: Codable, Sendable {
    let status: Bool?
    let message: String?
    let isBoughtData: IsBoughtData?

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case isBoughtData = "data" // maps JSON key "data" → isBoughtData
    }
    
    
    var isValid: Bool {
        return status == true && isBoughtData?.videoUrl != nil && isBoughtData?.videoUrl != ""
    }
}


struct IsBoughtData: Codable {
    let videoUrl: String?
}
