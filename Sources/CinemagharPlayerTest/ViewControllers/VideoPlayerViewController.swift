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
    private var castButton: UIButton!
    
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
        setupCustomCastButton()
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
        
        // Disable AirPlay and Picture-in-Picture
        playerViewController.allowsPictureInPicturePlayback = false
        
        // Disable the default AirPlay button (iOS 11+)
        if #available(iOS 11.0, *) {
            playerViewController.exitsFullScreenWhenPlaybackEnds = true
        }
        
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
    
    private func setupCustomCastButton() {
        castButton = UIButton(type: .system)
        
        // Use SF Symbol for cast icon (available iOS 13+)
        if #available(iOS 13.0, *) {
            let castImage = UIImage(systemName: "airplayvideo")
            castButton.setImage(castImage, for: .normal)
        } else {
            // Fallback for older iOS versions - you can add a custom cast image to your assets
            castButton.setTitle("Cast", for: .normal)
        }
        
        castButton.tintColor = .white
        castButton.translatesAutoresizingMaskIntoConstraints = false
        castButton.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        
        // Add button to the content overlay view
        if let overlayView = playerViewController.contentOverlayView {
            overlayView.addSubview(castButton)
            
            // Position the button in the top-right corner (like AirPlay typically appears)
            NSLayoutConstraint.activate([
                castButton.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 16),
                castButton.trailingAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                castButton.widthAnchor.constraint(equalToConstant: 44),
                castButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            // Optional: Add a semi-transparent background for better visibility
            castButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            castButton.layer.cornerRadius = 8
        }
    }
    
    @objc private func castButtonTapped() {
        // Implement your custom cast logic here
        print("Cast button tapped")
        
        // Example: Show a cast device picker
        showCastDevicePicker()
        
        // Or handle Google Cast, Chromecast, or any other casting service
        // initiateCasting()
    }
    
    private func showCastDevicePicker() {
        // This is where you'd implement your casting logic
        // For example, showing a list of available cast devices
        
        let alert = UIAlertController(
            title: "Cast to Device",
            message: "Select a device to cast to",
            preferredStyle: .actionSheet
        )
        
        // Add your cast devices here
        alert.addAction(UIAlertAction(title: "Living Room TV", style: .default) { _ in
            self.startCasting(to: "Living Room TV")
        })
        
        alert.addAction(UIAlertAction(title: "Bedroom TV", style: .default) { _ in
            self.startCasting(to: "Bedroom TV")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = castButton
            popover.sourceRect = castButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func startCasting(to device: String) {
        print("Starting cast to: \(device)")
        
        // Implement your casting logic here
        // This might involve:
        // 1. Pausing local playback
        // 2. Sending video URL to cast device
        // 3. Showing casting controls
        // 4. Monitoring cast status
        
        // Example for Google Cast SDK:
        // GCKCastContext.sharedInstance().sessionManager.startSession(with: device)
        
        // Update button appearance to show active casting
        updateCastButtonForActiveSession()
    }
    
    private func updateCastButtonForActiveSession() {
        // Update the button to show casting is active
        if #available(iOS 13.0, *) {
            let connectedImage = UIImage(systemName: "airplayvideo.circle.fill")
            castButton.setImage(connectedImage, for: .normal)
        }
        castButton.tintColor = .systemBlue
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
