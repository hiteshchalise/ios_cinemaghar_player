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
    
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var watermarkLabel: UILabel!
    private var watermarkTimer: Timer?
    
    // Custom Controls
    private var controlsContainerView: UIView!
    private var playPauseButton: UIButton!
    private var castButton: UIButton!
    private var progressSlider: UISlider!
    private var currentTimeLabel: UILabel!
    private var durationLabel: UILabel!
    private var controlsVisible = true
    private var controlsTimer: Timer?
    private var timeObserver: Any?
    
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
        view.backgroundColor = .black
        setupPlayer()
        setupPlayerLayer()
        setupCustomControls()
        setupWatermark()
        setupGestureRecognizers()
        addPlayerObservers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lockOrientation(.landscape)
        
        if configuration.autoPlay {
            player.play()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        watermarkTimer?.invalidate()
        watermarkTimer = nil
        controlsTimer?.invalidate()
        controlsTimer = nil
        unlockOrientation()
    }
    
    // MARK: - Setup
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false // Disable AirPlay
    }
    
    private func setupPlayerLayer() {
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
    }
    
    private func setupCustomControls() {
        // Container for all controls
        controlsContainerView = UIView()
        controlsContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        controlsContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsContainerView)
        
        // Play/Pause Button
        playPauseButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        playPauseButton.tintColor = .white
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        controlsContainerView.addSubview(playPauseButton)
        
        // Cast Button
        castButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            castButton.setImage(UIImage(systemName: "airplayvideo"), for: .normal)
        }
        castButton.tintColor = .white
        castButton.translatesAutoresizingMaskIntoConstraints = false
        castButton.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        controlsContainerView.addSubview(castButton)
        
        // Progress Slider
        progressSlider = UISlider()
        progressSlider.minimumValue = 0
        progressSlider.tintColor = .white
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchEnded), for: [.touchUpInside, .touchUpOutside])
        controlsContainerView.addSubview(progressSlider)
        
        // Time Labels
        currentTimeLabel = UILabel()
        currentTimeLabel.text = "0:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .systemFont(ofSize: 12)
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.addSubview(currentTimeLabel)
        
        durationLabel = UILabel()
        durationLabel.text = "0:00"
        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 12)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.addSubview(durationLabel)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            // Controls Container
            controlsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Play/Pause Button
            playPauseButton.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: 16),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 44),
            playPauseButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Cast Button
            castButton.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -16),
            castButton.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor),
            castButton.widthAnchor.constraint(equalToConstant: 44),
            castButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Current Time Label
            currentTimeLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 12),
            currentTimeLabel.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor),
            
            // Duration Label
            durationLabel.trailingAnchor.constraint(equalTo: castButton.leadingAnchor, constant: -12),
            durationLabel.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor),
            
            // Progress Slider
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 12),
            progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -12),
            progressSlider.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor)
        ])
    }
    
    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func addPlayerObservers() {
        // Update duration when item is ready
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        // Update progress
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
        
        // Update duration
        player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            Task { @MainActor in
                self?.updateDuration()
            }
        }
    }
    
    private func updateProgress() {
        guard let currentItem = player.currentItem else { return }
        let currentTime = CMTimeGetSeconds(currentItem.currentTime())
        let duration = CMTimeGetSeconds(currentItem.duration)
        
        if !duration.isNaN && !duration.isInfinite {
            progressSlider.maximumValue = Float(duration)
            progressSlider.value = Float(currentTime)
            currentTimeLabel.text = formatTime(currentTime)
        }
    }
    
    private func updateDuration() {
        guard let duration = player.currentItem?.duration else { return }
        let seconds = CMTimeGetSeconds(duration)
        if !seconds.isNaN && !seconds.isInfinite {
            durationLabel.text = formatTime(seconds)
            progressSlider.maximumValue = Float(seconds)
        }
    }
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Control Actions
    @objc private func handleTap() {
        if controlsVisible {
            hideControls()
        } else {
            showControls()
        }
    }
    
    private func showControls() {
        controlsVisible = true
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 1.0
        }
        resetControlsTimer()
    }
    
    private func hideControls() {
        controlsVisible = false
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 0.0
        }
        controlsTimer?.invalidate()
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                if self?.player.timeControlStatus == .playing {
                    self?.hideControls()
                }
            }
        }
    }
    
    @objc private func playPauseTapped() {
        if player.timeControlStatus == .playing {
            player.pause()
            if #available(iOS 13.0, *) {
                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        } else {
            player.play()
            if #available(iOS 13.0, *) {
                playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }
            resetControlsTimer()
        }
    }
    
    @objc private func sliderValueChanged() {
        let seconds = Double(progressSlider.value)
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time)
    }
    
    @objc private func sliderTouchEnded() {
        if player.timeControlStatus == .playing {
            resetControlsTimer()
        }
    }
    
    @objc private func castButtonTapped() {
        showCastDevicePicker()
    }
    
    @objc private func playerItemDidReachEnd() {
        player.seek(to: .zero)
        if #available(iOS 13.0, *) {
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }
    
    private func showCastDevicePicker() {
        let alert = UIAlertController(
            title: "Cast to Device",
            message: "Select a device to cast to",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Living Room TV", style: .default) { _ in
            self.startCasting(to: "Living Room TV")
        })
        
        alert.addAction(UIAlertAction(title: "Bedroom TV", style: .default) { _ in
            self.startCasting(to: "Bedroom TV")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = castButton
            popover.sourceRect = castButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func startCasting(to device: String) {
        print("Starting cast to: \(device)")
        // Implement casting logic
        updateCastButtonForActiveSession()
    }
    
    private func updateCastButtonForActiveSession() {
        if #available(iOS 13.0, *) {
            castButton.setImage(UIImage(systemName: "airplayvideo.circle.fill"), for: .normal)
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
        view.addSubview(watermarkLabel)
        
        positionWatermarkRandomly()
        
        watermarkTimer = Timer.scheduledTimer(withTimeInterval: 14.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.positionWatermarkRandomly()
            }
        }
    }
    
    private func positionWatermarkRandomly() {
        let labelWidth = watermarkLabel.intrinsicContentSize.width
        let labelHeight = watermarkLabel.intrinsicContentSize.height
        
        let margin: CGFloat = 50
        let maxX = view.bounds.width - labelWidth - margin
        let maxY = view.bounds.height - labelHeight - margin - 80 // Account for controls
        
        let randomX = CGFloat.random(in: margin...max(margin, maxX))
        let randomY = CGFloat.random(in: margin...max(margin, maxY))
        
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
    
    deinit {
        MainActor.assumeIsolated {
            if let observer = timeObserver {
                player?.removeTimeObserver(observer)
            }
            NotificationCenter.default.removeObserver(self)
            watermarkTimer?.invalidate()
            controlsTimer?.invalidate()
            player?.pause()
            unlockOrientation()
        }
    }
}
