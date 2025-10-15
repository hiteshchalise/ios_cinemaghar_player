//
//  VideoPlayerViewController.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import UIKit
import AVKit
import AVFoundation

@MainActor
internal class VideoPlayerViewController: UIViewController {
    
    // MARK: - Properties
    private let videoURL: URL
    private let configuration: VideoPlayerConfiguration
    private let apiResponse: APIResponse
    
    private var playerViewController: AVPlayerViewController!
    private var player: AVPlayer!
    private var watermarkLabel: UILabel!
    private var watermarkTimer: Timer?
    
    // MARK: - Initialization
    init(videoURL: URL, configuration: VideoPlayerConfiguration, apiResponse: APIResponse) {
        self.videoURL = videoURL
        self.configuration = configuration
        self.apiResponse = apiResponse
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupPlayerViewController()
        setupWatermark()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Lock to landscape when view appears
        lockOrientation(.landscape)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        watermarkTimer?.invalidate()
        watermarkTimer = nil
        // Unlock orientation when leaving
        unlockOrientation()
    }
    
    // MARK: - Setup
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
    }
    
    private func setupPlayerViewController() {
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = true
        playerViewController.allowsPictureInPicturePlayback = true
        
        // Add player view controller as child
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds
        playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerViewController.didMove(toParent: self)
        
        // Auto-play if configured
        if configuration.autoPlay {
            player.play()
        }
    }
    
    private func setupWatermark() {
        guard !configuration.userUniqueId.isEmpty else { return }
        
        watermarkLabel = UILabel()
        watermarkLabel.text = configuration.userUniqueId
        watermarkLabel.textColor = UIColor.white.withAlphaComponent(0.4)
        watermarkLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        watermarkLabel.sizeToFit()
        watermarkLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if let overlayView = playerViewController.contentOverlayView {
            overlayView.addSubview(watermarkLabel)
            
            // Position randomly and start timer
            positionWatermarkRandomly()
            
            // Change position every 14 seconds
            watermarkTimer = Timer.scheduledTimer(withTimeInterval: 14.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.positionWatermarkRandomly()
                }
            }
        }
    }
    
    private func positionWatermarkRandomly() {
        guard let overlayView = playerViewController.contentOverlayView else { return }
        
        // Remove previous constraints
        watermarkLabel.removeConstraints(watermarkLabel.constraints)
        NSLayoutConstraint.deactivate(overlayView.constraints.filter { constraint in
            constraint.firstItem as? UILabel == watermarkLabel ||
            constraint.secondItem as? UILabel == watermarkLabel
        })
        
        let labelWidth = watermarkLabel.intrinsicContentSize.width
        let labelHeight = watermarkLabel.intrinsicContentSize.height
        
        // Generate random position with safe margins
        let margin: CGFloat = 50
        let maxX = overlayView.bounds.width - labelWidth - margin
        let maxY = overlayView.bounds.height - labelHeight - margin
        
        let randomX = CGFloat.random(in: margin...max(margin, maxX))
        let randomY = CGFloat.random(in: margin...max(margin, maxY))
        
        // Subtle fade out, move, then fade in
        UIView.animate(withDuration: 0.3, animations: {
            self.watermarkLabel.alpha = 0
        }) { _ in
            self.watermarkLabel.frame = CGRect(x: randomX, y: randomY, width: labelWidth, height: labelHeight)
            UIView.animate(withDuration: 0.3) {
                self.watermarkLabel.alpha = 0.4
            }
        }
    }
    
    // MARK: - Orientation Control
    private func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if #available(iOS 16.0, *) {
            if let windowScene = view.window?.windowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            }
        } else {
            // For iOS 15 and below
            if let orientationValue = orientationToInterfaceOrientation(orientation) {
                UIDevice.current.setValue(orientationValue.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
    
    private func unlockOrientation() {
        if #available(iOS 16.0, *) {
            if let windowScene = view.window?.windowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
            }
        }
        // For iOS 15 and below, the orientation is controlled by supportedInterfaceOrientations
        // which gets reset when the VC is dismissed
    }
    
    private func orientationToInterfaceOrientation(_ mask: UIInterfaceOrientationMask) -> UIInterfaceOrientation? {
        switch mask {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight, .landscape: return .landscapeRight
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return nil
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    // MARK: - Actions
    // The native AVPlayerViewController handles the Done button and AirPlay automatically
    // To handle the Done button dismiss action, the presenting view controller
    // can set itself as the delegate or use modal presentation callbacks
    
    deinit {
        MainActor.assumeIsolated {
            watermarkTimer?.invalidate()
            watermarkTimer = nil
            player?.pause()
            unlockOrientation()
        }
    }
}
