//
//  APIResponse.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import Foundation

public struct APIResponse: Codable {
    let status: Bool?
    let message: String?
    let isBoughtData: IsBoughtData?

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case isBoughtData = "data" // maps JSON key "data" → isBoughtData
    }
}


struct IsBoughtData: Codable {
    let videoUrl: String?
}
