//
//  VideoPlayerSDK.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import UIKit

public class VideoPlayerSDK {
    
    // MARK: - Properties
    public weak var delegate: VideoPlayerDelegate?
    public let configuration: VideoPlayerConfiguration
    
    private let apiManager = APIManager()
    private var navigationController: UINavigationController?
    private var introViewController: IntroViewController?
    
    // MARK: - Initialization
    public init(configuration: VideoPlayerConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    public func present(from presentingViewController: UIViewController, animated: Bool = true) {
        let introVC = IntroViewController(configuration: configuration)
        introVC.delegate = self
        
        let navController = UINavigationController(rootViewController: introVC)
        navController.modalPresentationStyle = .fullScreen
        navController.setNavigationBarHidden(true, animated: false)
        
        self.navigationController = navController
        self.introViewController = introVC
        
        presentingViewController.present(navController, animated: animated)
        
        // Start API call
        delegate?.videoPlayerDidStartLoading(self)
        loadVideoData()
    }
    
    public func dismiss(animated: Bool = true) {
        navigationController?.dismiss(animated: animated) { [weak self] in
            guard let self = self else { return }
            self.delegate?.videoPlayerDidDismiss(self)
        }
    }
    
    // MARK: - Private Methods
    private func loadVideoData() {
        apiManager.fetchVideoData(
            from: configuration.apiEndpoint,
            headers: configuration.apiHeaders,
            timeout: configuration.requestTimeout
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if let videoURLString = response.isBoughtData?.videoUrl,
                   let videoURL = URL(string: videoURLString) {
                    self.delegate?.videoPlayer(self, didReceiveVideoURL: videoURL)
                    self.navigateToPlayer(with: videoURL, response: response)
                } else {
                    self.delegate?.videoPlayer(self, didFailToLoadWithError: .noVideoURLInResponse)
                }
                
            case .failure(let error):
                self.delegate?.videoPlayer(self, didFailToLoadWithError: error)
            }
        }
    }
    
    private func navigateToPlayer(with url: URL, response: APIResponse) {
        let playerVC = VideoPlayerViewController(
            videoURL: url,
            configuration: configuration,
            apiResponse: response
        )
        playerVC.delegate = self
        
        navigationController?.pushViewController(playerVC, animated: true)
    }
}

// MARK: - IntroViewControllerDelegate
extension VideoPlayerSDK: IntroViewControllerDelegate {
    func introViewControllerDidRequestDismiss(_ controller: IntroViewController) {
        dismiss()
    }
}

// MARK: - VideoPlayerViewControllerDelegate
extension VideoPlayerSDK: VideoPlayerViewControllerDelegate {
    func videoPlayerViewControllerDidRequestDismiss(_ controller: VideoPlayerViewController) {
        dismiss()
    }
    
    func videoPlayerViewController(_ controller: VideoPlayerViewController, didChangeState state: VideoPlayerState) {
        // Forward to main delegate if needed
    }
    
    func videoPlayerViewController(_ controller: VideoPlayerViewController, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval) {
        // Forward to main delegate if needed
    }
    
    func videoPlayerViewController(_ controller: VideoPlayerViewController, didEncounterError error: VideoPlayerError) {
        delegate?.videoPlayer(controller.videoPlayerView, didEncounterError: error)
    }
    
    func videoPlayerViewControllerDidFinishPlaying(_ controller: VideoPlayerViewController) {
        delegate?.videoPlayerDidFinishPlaying(controller.videoPlayerView)
    }
}
