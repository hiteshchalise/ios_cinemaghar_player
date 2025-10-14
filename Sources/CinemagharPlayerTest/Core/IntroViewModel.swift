//
//  IntroViewModel.swift
//  CinemagharPlayerTest
//
//  Created by Hitesh Chalise on 14/10/2025.
//
import SwiftUI


@MainActor
class IntroViewModel: ObservableObject {
    @Published var loadingState: LoadingState = .loading
    
    private let configuration: VideoPlayerConfiguration
    private var loadTask: Task<Void, Never>?
    
    var onSuccess: ((URL, APIResponse) -> Void)?
    
    init(configuration: VideoPlayerConfiguration) {
        self.configuration = configuration
    }
    
    func loadVideoData() {
        loadTask?.cancel()
        loadingState = .loading
        
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
                
                try Task.checkCancellation()
                
                guard let videoURLString = response.isBoughtData?.videoUrl,
                      let videoURL = URL(string: videoURLString) else {
                    loadingState = .error(.invalidResponseData)
                    return
                }
                
                print("✅ Video loaded successfully")
                onSuccess?(videoURL, response)
                
            } catch is CancellationError {
                print("Video load was cancelled")
            } catch {
                loadingState = .error(convertError(error))
            }
        }
    }
    
    func retry() {
        print("🔄 Retry requested")
        loadVideoData()
    }
    
    func cancelLoad() {
        print("🛑 Cancelling load task")
        loadTask?.cancel()
        loadTask = nil
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
}


// MARK: - Loading State
enum LoadingState {
    case loading
    case error(VideoPlayerError)
}
