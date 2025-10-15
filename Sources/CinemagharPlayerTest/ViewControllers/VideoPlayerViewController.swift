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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Lock to landscape when view appears
        lockOrientation(.landscape)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
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
        
        // Add custom back button
        setupBackButton()
        
        // Auto-play if configured
        if configuration.autoPlay {
            player.play()
        }
    }
    
    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.setTitle("✕", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backButton.layer.cornerRadius = 22
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Add to the player view controller's content overlay view
        if let overlayView = playerViewController.contentOverlayView {
            overlayView.addSubview(backButton)
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 16),
                backButton.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 16),
                backButton.widthAnchor.constraint(equalToConstant: 44),
                backButton.heightAnchor.constraint(equalToConstant: 44)
            ])
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
    @objc private func backButtonTapped() {
        player?.pause()
        dismiss(animated: true)
    }
    
    deinit {
        MainActor.assumeIsolated {
            player?.pause()
            unlockOrientation()
        }
    }
}
