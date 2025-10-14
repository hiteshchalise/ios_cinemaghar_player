//
//  VideoPlayerSDK.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import UIKit

@MainActor
public class VideoPlayerSDK {
    
    // MARK: - Properties
    weak var delegate: VideoPlayerDelegate?
    public let configuration: VideoPlayerConfiguration
    
    private var navigationController: UINavigationController?
    private var introViewController: IntroViewController?
    private var loadTask: Task<Void, Never>?
    
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
        print("🚪 Dismissing VideoPlayerSDK")
        print("   navigationController: \(navigationController != nil)")
        print(
            "   navigationController.presentingViewController: \(navigationController?.presentingViewController != nil)"
        )
            
        // Cancel ongoing API task
        cancelLoad()
            
        // The navigationController is what was presented, so we dismiss it
        // We need to call dismiss on the navigationController itself
        // because it was presented modally
        navigationController?.dismiss(animated: animated) { [weak self] in
            guard let self = self else { return }
            print("✅ VideoPlayerSDK dismissed")
            self.delegate?.videoPlayerDidDismiss(self)
                
            // Clean up references
            self.navigationController = nil
            self.introViewController = nil
        }
    }
    
    // MARK: - Private Methods
    private func loadVideoData() {
        // Cancel any existing task
        loadTask?.cancel()
        
        loadTask = Task {
            do {
                print("----> Loading video data")
                let response = try await APIManager().fetchVideoData(
                    userUniqueId: configuration.userUniqueId,
                    contentId: configuration.contentId,
                    authToken: configuration.authToken,
                    deviceId: configuration.deviceId,
                    deviceName: configuration.deviceName
                )
                print("----> API call finished \(response)")
                
                // Check if task was cancelled
                try Task.checkCancellation()
                
                guard let videoURLString = response.isBoughtData?.videoUrl,
                      let videoURL = URL(string: videoURLString) else {
                    notifyError(.invalidResponseData)
                    return
                }
                
                notifySuccess(videoURL: videoURL, response: response)
                
            } catch is CancellationError {
                // Task was cancelled, don't notify error
                print("Video load was cancelled")
            } catch {
                notifyError(convertError(error))
            }
        }
    }

    @MainActor
    private func notifySuccess(videoURL: URL, response: APIResponse) {
        print("✅ Video loaded successfully, navigating to player")
        self.delegate?.videoPlayer(self, didReceiveVideoURL: videoURL)
        self.navigateToPlayer(with: videoURL, response: response)
    }

    @MainActor
    private func notifyError(_ error: VideoPlayerError) {
        print("❌ Notifying error: \(error)")
        
        // Show error in IntroViewController
        introViewController?.showError(error)
        
        // Notify delegate
        self.delegate?.videoPlayer(self, didFailToLoadWithError: error)
    }

    private func convertError(_ error: Error) -> VideoPlayerError {
        if let videoError = error as? VideoPlayerError {
            return videoError
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError("No internet connection")
            case .timedOut:
                return .networkError("Request timed out")
            case .cancelled:
                return .networkError("Request cancelled")
            default:
                return .networkError(urlError.localizedDescription)
            }
        } else {
            return .networkError(error.localizedDescription)
        }
    }

    func cancelLoad() {
        print("🛑 Cancelling load task")
        loadTask?.cancel()
        loadTask = nil
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
        print("📱 IntroViewController requested dismiss")
        print("   SDK self: \(Unmanaged.passUnretained(self).toOpaque())")
        dismiss()
    }
    
    func introViewControllerDidRequestRetry() {
        loadVideoData()
    }
}

// MARK: - VideoPlayerViewControllerDelegate
extension VideoPlayerSDK: VideoPlayerViewControllerDelegate {
    func videoPlayerViewControllerDidRequestDismiss(_ controller: VideoPlayerViewController) {
        print("📱 VideoPlayerViewController requested dismiss")
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
