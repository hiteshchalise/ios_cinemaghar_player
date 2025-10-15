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
        setupCastButton()
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
        
        // Animate to new position
        UIView.animate(withDuration: 0.5) {
            self.watermarkLabel.frame = CGRect(x: randomX, y: randomY, width: labelWidth, height: labelHeight)
        }
    }
    
    private func setupCastButton() {
        // Create cast button
        let castButton = UIButton(type: .system)
        castButton.setImage(UIImage(systemName: "airplayvideo"), for: .normal)
        castButton.tintColor = .white
        castButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        castButton.layer.cornerRadius = 22
        castButton.translatesAutoresizingMaskIntoConstraints = false
        castButton.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        
        // Add to the player view controller's content overlay view
        if let overlayView = playerViewController.contentOverlayView {
            overlayView.addSubview(castButton)
            NSLayoutConstraint.activate([
                castButton.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 16),
                castButton.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -16),
                castButton.widthAnchor.constraint(equalToConstant: 44),
                castButton.heightAnchor.constraint(equalToConstant: 44)
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
    
    @objc private func castButtonTapped() {
        // TODO: Add your casting logic here
        // Example: Initialize Google Cast or AirPlay picker
        
        // For native AirPlay, you can use:
        // let routePickerView = AVRoutePickerView()
        // routePickerView.showRoutePickerButton(from: castButton, animated: true)
        
        print("Cast button tapped - implement your casting logic here")
    }
    
    deinit {
        MainActor.assumeIsolated {
            watermarkTimer?.invalidate()
            watermarkTimer = nil
            player?.pause()
            unlockOrientation()
        }
    }
}
