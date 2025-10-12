//
//  VideoPlayerConfigurlation.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import Foundation
import UIKit

public class VideoPlayerConfiguration {
    // Player Configuration
    public var autoPlay: Bool = true
    public var showControls: Bool = true
    public var allowFullScreen: Bool = true
    public var backgroundColor: UIColor = .black
    public var controlsTimeout: TimeInterval = 3.0
    
    // API Configuration
    public var apiEndpoint: String = ""
    public var apiHeaders: [String: String] = [:]
    public var requestTimeout: TimeInterval = 30.0
    
    // Intro Screen Configuration
    public var introBackgroundColor: UIColor = .black
    public var loadingIndicatorColor: UIColor = .white
    public var loadingText: String? = nil
    
    public init() {}
}
