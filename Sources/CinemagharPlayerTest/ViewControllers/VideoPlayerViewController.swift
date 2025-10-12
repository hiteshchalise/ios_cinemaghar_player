//
//  VideoPlayerViewController.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import UIKit
import AVFoundation

@MainActor
protocol VideoPlayerViewControllerDelegate: AnyObject {
    func videoPlayerViewControllerDidRequestDismiss(_ controller: VideoPlayerViewController)
    func videoPlayerViewController(_ controller: VideoPlayerViewController, didChangeState state: VideoPlayerState)
    func videoPlayerViewController(_ controller: VideoPlayerViewController, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval)
    func videoPlayerViewController(_ controller: VideoPlayerViewController, didEncounterError error: VideoPlayerError)
    func videoPlayerViewControllerDidFinishPlaying(_ controller: VideoPlayerViewController)
}

@MainActor
internal class VideoPlayerViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: VideoPlayerViewControllerDelegate?
    private let videoURL: URL
    private let configuration: VideoPlayerConfiguration
    private let apiResponse: APIResponse
    
    // MARK: - UI Components
    private(set) lazy var videoPlayerView: VideoPlayerView = {
        let playerView = VideoPlayerView()
        playerView.configuration = configuration
        playerView.delegate = self
        return playerView
    }()
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        return button
    }()
    
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
        setupUI()
        loadAndPlayVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoPlayerView.pause()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = configuration.backgroundColor
        
        // Add video player view
        view.addSubview(videoPlayerView)
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoPlayerView.topAnchor.constraint(equalTo: view.topAnchor),
            videoPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add dismiss button
        view.addSubview(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dismissButton.widthAnchor.constraint(equalToConstant: 44),
            dismissButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func loadAndPlayVideo() {
        videoPlayerView.loadVideo(from: videoURL)
    }
    
    // MARK: - Actions
    @objc private func dismissButtonTapped() {
        delegate?.videoPlayerViewControllerDidRequestDismiss(self)
    }
}

// MARK: - VideoPlayerDelegate
extension VideoPlayerViewController: VideoPlayerDelegate {
    func videoPlayerDidStartLoading(_ sdk: VideoPlayerSDK) {
        // Not used in this context
    }
    
    func videoPlayer(_ sdk: VideoPlayerSDK, didFailToLoadWithError error: VideoPlayerError) {
        // Not used in this context
    }
    
    func videoPlayer(_ sdk: VideoPlayerSDK, didReceiveVideoURL url: URL) {
        // Not used in this context
    }
    
    func videoPlayer(_ player: VideoPlayerView, didChangeState state: VideoPlayerState) {
        delegate?.videoPlayerViewController(self, didChangeState: state)
    }
    
    func videoPlayer(_ player: VideoPlayerView, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval) {
        delegate?.videoPlayerViewController(self, didUpdateProgress: currentTime, totalTime: totalTime)
    }
    
    func videoPlayer(_ player: VideoPlayerView, didEncounterError error: VideoPlayerError) {
        delegate?.videoPlayerViewController(self, didEncounterError: error)
    }
    
    func videoPlayerDidFinishPlaying(_ player: VideoPlayerView) {
        delegate?.videoPlayerViewControllerDidFinishPlaying(self)
    }
    
    func videoPlayerDidDismiss(_ sdk: VideoPlayerSDK) {
        // Not used in this context
    }
}
