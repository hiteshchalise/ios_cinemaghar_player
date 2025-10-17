//
//  VideoPlayerViewController.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import UIKit
import AVKit
import AVFoundation
import SwiftUI

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
    
    // Top Controls
    private var topControlsView: UIView!
    private var backButton: UIButton!
    private var titleLabel: UILabel!
    private var castButton: UIButton!
    
    // Center Controls
    private var centerControlsView: UIView!
    private var backwardButton: UIButton!
    private var playPauseButton: UIButton!
    private var forwardButton: UIButton!
    
    // Bottom Controls
    private var bottomControlsView: UIView!
    private var progressSlider: UISlider!
    private var currentTimeLabel: UILabel!
    private var durationLabel: UILabel!
    private var settingsButton: UIButton!
    
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
        setupTopControls()
        setupCenterControls()
        setupBottomControls()
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
            updatePlayPauseButton()
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
    
    // MARK: - Setup Player
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false
    }
    
    private func setupPlayerLayer() {
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
    }
    
    // MARK: - Setup Top Controls
    private func setupTopControls() {
        topControlsView = UIView()
        topControlsView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        topControlsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topControlsView)
        
        // Back Button
        backButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        } else {
            backButton.setTitle("←", for: .normal)
        }
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        topControlsView.addSubview(backButton)
        
        // Title Label
        titleLabel = UILabel()
        titleLabel.text = configuration.contentTitle
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topControlsView.addSubview(titleLabel)
        
        // Cast Button
        castButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            castButton.setImage(UIImage(systemName: "airplayvideo"), for: .normal)
        } else {
            castButton.setTitle("Cast", for: .normal)
        }
        castButton.tintColor = .white
        castButton.translatesAutoresizingMaskIntoConstraints = false
        castButton.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        topControlsView.addSubview(castButton)
        
        NSLayoutConstraint.activate([
            topControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topControlsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topControlsView.heightAnchor.constraint(equalToConstant: 60),
            
            backButton.leadingAnchor.constraint(equalTo: topControlsView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            castButton.trailingAnchor.constraint(equalTo: topControlsView.trailingAnchor, constant: -16),
            castButton.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            castButton.widthAnchor.constraint(equalToConstant: 44),
            castButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: topControlsView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: castButton.leadingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Setup Center Controls
    private func setupCenterControls() {
        centerControlsView = UIView()
        centerControlsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(centerControlsView)
        
        // Backward Button
        backwardButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            backwardButton.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
        } else {
            backwardButton.setTitle("<<", for: .normal)
        }
        backwardButton.tintColor = .white
        backwardButton.translatesAutoresizingMaskIntoConstraints = false
        backwardButton.addTarget(self, action: #selector(backwardTapped), for: .touchUpInside)
        centerControlsView.addSubview(backwardButton)
        
        // Play/Pause Button
        playPauseButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            playPauseButton.setTitle("▶", for: .normal)
        }
        playPauseButton.tintColor = .white
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        centerControlsView.addSubview(playPauseButton)
        
        // Forward Button
        forwardButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            forwardButton.setImage(UIImage(systemName: "goforward.10"), for: .normal)
        } else {
            forwardButton.setTitle(">>", for: .normal)
        }
        forwardButton.tintColor = .white
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        centerControlsView.addSubview(forwardButton)
        
        // Apply larger size to center buttons
        let buttonSize: CGFloat = 60
        
        NSLayoutConstraint.activate([
            centerControlsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerControlsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            playPauseButton.centerXAnchor.constraint(equalTo: centerControlsView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: centerControlsView.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: buttonSize),
            playPauseButton.heightAnchor.constraint(equalToConstant: buttonSize),
            
            backwardButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -40),
            backwardButton.centerYAnchor.constraint(equalTo: centerControlsView.centerYAnchor),
            backwardButton.widthAnchor.constraint(equalToConstant: 50),
            backwardButton.heightAnchor.constraint(equalToConstant: 50),
            
            forwardButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 40),
            forwardButton.centerYAnchor.constraint(equalTo: centerControlsView.centerYAnchor),
            forwardButton.widthAnchor.constraint(equalToConstant: 50),
            forwardButton.heightAnchor.constraint(equalToConstant: 50),
            
            centerControlsView.leadingAnchor.constraint(equalTo: backwardButton.leadingAnchor),
            centerControlsView.trailingAnchor.constraint(equalTo: forwardButton.trailingAnchor),
            centerControlsView.topAnchor.constraint(equalTo: playPauseButton.topAnchor),
            centerControlsView.bottomAnchor.constraint(equalTo: playPauseButton.bottomAnchor)
        ])
        
        // Add visual styling
        playPauseButton.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        playPauseButton.layer.cornerRadius = buttonSize / 2
        
        backwardButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        backwardButton.layer.cornerRadius = 25
        
        forwardButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        forwardButton.layer.cornerRadius = 25
    }
    
    // MARK: - Setup Bottom Controls
    private func setupBottomControls() {
        bottomControlsView = UIView()
        bottomControlsView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        bottomControlsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomControlsView)
        
        // Current Time Label
        currentTimeLabel = UILabel()
        currentTimeLabel.text = "0:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .systemFont(ofSize: 12)
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomControlsView.addSubview(currentTimeLabel)
        
        // Progress Slider
        progressSlider = UISlider()
        progressSlider.minimumValue = 0
        progressSlider.tintColor = .white
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchEnded), for: [.touchUpInside, .touchUpOutside])
        bottomControlsView.addSubview(progressSlider)
        
        // Duration Label
        durationLabel = UILabel()
        durationLabel.text = "0:00"
        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 12)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomControlsView.addSubview(durationLabel)
        
        // Settings Button
        settingsButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        } else {
            settingsButton.setTitle("⚙", for: .normal)
        }
        settingsButton.tintColor = .white
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        bottomControlsView.addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            bottomControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomControlsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomControlsView.heightAnchor.constraint(equalToConstant: 60),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: bottomControlsView.leadingAnchor, constant: 16),
            currentTimeLabel.centerYAnchor.constraint(equalTo: bottomControlsView.centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 50),
            
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 12),
            progressSlider.centerYAnchor.constraint(equalTo: bottomControlsView.centerYAnchor),
            
            durationLabel.leadingAnchor.constraint(equalTo: progressSlider.trailingAnchor, constant: 12),
            durationLabel.centerYAnchor.constraint(equalTo: bottomControlsView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 50),
            
            settingsButton.leadingAnchor.constraint(equalTo: durationLabel.trailingAnchor, constant: 12),
            settingsButton.trailingAnchor.constraint(equalTo: bottomControlsView.trailingAnchor, constant: -16),
            settingsButton.centerYAnchor.constraint(equalTo: bottomControlsView.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Setup Observers
    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func addPlayerObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
        
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
            self.topControlsView.alpha = 1.0
            self.centerControlsView.alpha = 1.0
            self.bottomControlsView.alpha = 1.0
        }
        resetControlsTimer()
    }
    
    private func hideControls() {
        controlsVisible = false
        UIView.animate(withDuration: 0.3) {
            self.topControlsView.alpha = 0.0
            self.centerControlsView.alpha = 0.0
            self.bottomControlsView.alpha = 0.0
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
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func playPauseTapped() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
            resetControlsTimer()
        }
        updatePlayPauseButton()
    }
    
    private func updatePlayPauseButton() {
        if #available(iOS 13.0, *) {
            let imageName = player.timeControlStatus == .playing ? "pause.fill" : "play.fill"
            playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    @objc private func backwardTapped() {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(currentTime - 10, 0)
        let seekTime = CMTime(seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: seekTime)
        resetControlsTimer()
    }
    
    @objc private func forwardTapped() {
        guard let duration = player.currentItem?.duration else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let maxTime = CMTimeGetSeconds(duration)
        let newTime = min(currentTime + 10, maxTime)
        let seekTime = CMTime(seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: seekTime)
        resetControlsTimer()
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
    
    @objc private func settingsButtonTapped() {
        showSettingsMenu()
    }
    
    private func showSettingsMenu() {
        let alert = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        
        // Quality options
        let qualityAction = UIAlertAction(title: "Quality", style: .default) { [weak self] _ in
            self?.showQualityOptions()
        }
        alert.addAction(qualityAction)
        
        // Speed options
        let speedAction = UIAlertAction(title: "Playback Speed", style: .default) { [weak self] _ in
            self?.showSpeedOptions()
        }
        alert.addAction(speedAction)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = settingsButton
            popover.sourceRect = settingsButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showQualityOptions() {
        let alert = UIAlertController(title: "Video Quality", message: "Select quality", preferredStyle: .actionSheet)
        
        let qualities = ["Auto", "1080p", "720p", "480p", "360p"]
        for quality in qualities {
            alert.addAction(UIAlertAction(title: quality, style: .default) { _ in
                print("Selected quality: \(quality)")
                // Implement quality change logic here
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = settingsButton
            popover.sourceRect = settingsButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showSpeedOptions() {
        let alert = UIAlertController(title: "Playback Speed", message: "Select speed", preferredStyle: .actionSheet)
        
        let speeds: [(String, Float)] = [
            ("0.5x", 0.5),
            ("0.75x", 0.75),
            ("Normal", 1.0),
            ("1.25x", 1.25),
            ("1.5x", 1.5),
            ("2x", 2.0)
        ]
        
        for (title, rate) in speeds {
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.player.rate = rate
                print("Playback speed set to: \(rate)")
            }
            if self.player.rate == rate {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = settingsButton
            popover.sourceRect = settingsButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func castButtonTapped() {
        showCastDevicePicker()
    }
    
    private func showCastDevicePicker() {
        let dialogVC = UIHostingController(rootView: CastDialogView(){ item in
            let player = item.createVideoPlayer("Cinemaghar")
            print("URL : ", self.videoURL)
            player.playContent(
                self.videoURL,
                title: self.configuration.contentTitle,
                thumbnailURL: URL(string: ""),
                completionHandler: { error in
                    if(error == nil) {
                        self.dismiss(animated: true, completion: {
                            self.backButtonTapped()
                        })
                    }
                })
            print("Playing content... \(item.name)")
        })
        
        dialogVC.overrideUserInterfaceStyle = .dark
        
        // Configure sheet presentation
        if let sheet = dialogVC.sheetPresentationController {
            sheet.detents = [.medium()]  // or .custom for specific height
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 10
        }
        
        present(dialogVC, animated: true)
    }
    
    private func startCasting(to device: String) {
        print("Starting cast to: \(device)")
        updateCastButtonForActiveSession()
    }
    
    private func updateCastButtonForActiveSession() {
        if #available(iOS 13.0, *) {
            castButton.setImage(UIImage(systemName: "airplayvideo.circle.fill"), for: .normal)
        }
        castButton.tintColor = .systemBlue
    }
    
    @objc private func playerItemDidReachEnd() {
        player.seek(to: .zero)
        updatePlayPauseButton()
    }
    
    // MARK: - Watermark
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
        
        let margin: CGFloat = 70
        let maxX = view.bounds.width - labelWidth - margin
        let maxY = view.bounds.height - labelHeight - margin
        
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
