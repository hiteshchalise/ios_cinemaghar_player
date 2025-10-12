//
//  VideoPlayerDelegate.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import Foundation
import AVFoundation

public protocol VideoPlayerDelegate: AnyObject {
    // API Events
    func videoPlayerDidStartLoading(_ sdk: VideoPlayerSDK)
    func videoPlayer(_ sdk: VideoPlayerSDK, didFailToLoadWithError error: VideoPlayerError)
    func videoPlayer(_ sdk: VideoPlayerSDK, didReceiveVideoURL url: URL)
    
    // Player Events
    func videoPlayer(_ player: VideoPlayerView, didChangeState state: VideoPlayerState)
    func videoPlayer(_ player: VideoPlayerView, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval)
    func videoPlayer(_ player: VideoPlayerView, didEncounterError error: VideoPlayerError)
    func videoPlayerDidFinishPlaying(_ player: VideoPlayerView)
    
    // Navigation Events
    func videoPlayerDidDismiss(_ sdk: VideoPlayerSDK)
}

// Make some methods optional
public extension VideoPlayerDelegate {
    func videoPlayerDidStartLoading(_ sdk: VideoPlayerSDK) {}
    func videoPlayer(_ sdk: VideoPlayerSDK, didReceiveVideoURL url: URL) {}
    func videoPlayer(_ player: VideoPlayerView, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval) {}
    func videoPlayerDidDismiss(_ sdk: VideoPlayerSDK) {}
}

public enum VideoPlayerState {
    case loading
    case ready
    case playing
    case paused
    case stopped
    case error
}
