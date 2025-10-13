//
//  VideoPlayerView.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//
import UIKit
import AVFoundation

@MainActor
public class VideoPlayerView: UIView {
    
    // MARK: - Public Properties
    public weak var delegate: VideoPlayerDelegate?
    public var configuration: VideoPlayerConfiguration = VideoPlayerConfiguration()
    
    public private(set) var state: VideoPlayerState = .stopped {
        didSet {
            delegate?.videoPlayer(self, didChangeState: state)
        }
    }
    
    // MARK: - Private Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    
    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayer()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayer()
    }
    
    // MARK: - Setup
    private func setupPlayer() {
        playerLayer = AVPlayerLayer()
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.backgroundColor = configuration.backgroundColor.cgColor
        layer.addSublayer(playerLayer!)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    // MARK: - Public Methods
    public func loadVideo(from url: URL) {
        guard url.scheme == "http" || url.scheme == "https" || url.scheme == "file" else {
            delegate?.videoPlayer(self, didEncounterError: .invalidURL)
            return
        }
        
        state = .loading
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        playerLayer?.player = player
        
        addPlayerObservers()
        
        if configuration.autoPlay {
            play()
        } else {
            state = .ready
        }
    }
    
    public func play() {
        player?.play()
        state = .playing
    }
    
    public func pause() {
        player?.pause()
        state = .paused
    }
    
    public func stop() {
        player?.pause()
        player?.seek(to: .zero)
        state = .stopped
    }
    
    public func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    // MARK: - Private Methods
    private func addPlayerObservers() {
        // Time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self, let player = self.player else { return }
                
                let currentTime = time.seconds
                let totalTime = player.currentItem?.duration.seconds ?? 0
                
                self.delegate?.videoPlayer(self, didUpdateProgress: currentTime, totalTime: totalTime)
            }
        }
        
        // Status observer
        player?.currentItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        // End time observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }
    
    @objc private func playerDidFinishPlaying() {
        state = .stopped
        delegate?.videoPlayerDidFinishPlaying(self)
    }
    
    nonisolated public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            guard let playerItem = object as? AVPlayerItem else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                switch playerItem.status {
                case .readyToPlay:
                    self.state = .ready
                case .failed:
                    if let error = playerItem.error {
                        self.delegate?.videoPlayer(self, didEncounterError: .playbackError(error))
                    }
                    self.state = .error
                default:
                    break
                }
            }
        }
    }
    
    deinit {
        MainActor.assumeIsolated {
            if let timeObserver = timeObserver {
                player?.removeTimeObserver(timeObserver)
            }
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
        }
        NotificationCenter.default.removeObserver(self)
    }
}
