//
//  IntroViewModel.swift
//  CinemagharPlayerTest
//
//  Created by Hitesh Chalise on 14/10/2025.
//
import SwiftUI
import Combine

// MARK: - Events
enum IntroViewModelEvent {
    case success(videoURL: URL, response: APIResponse)
    case error(VideoPlayerError)
}

@MainActor
class IntroViewModel: ObservableObject {
    @Published var loadingState: LoadingState = .loading
    
    let eventPublisher = PassthroughSubject<IntroViewModelEvent, Never>()
    
    private let configuration: VideoPlayerConfiguration
    private var loadTask: Task<Void, Never>?
    
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
                    let error = VideoPlayerError.invalidResponseData
                    loadingState = .error(error)
                    eventPublisher.send(.error(error))
                    return
                }
                
                print("✅ Video loaded successfully")
                eventPublisher.send(.success(videoURL: videoURL, response: response))
            } catch is CancellationError {
                print("Video load was cancelled")
            } catch {
                // Dummy
                print("Calling Success Dummy")
                let dummyURL = URL(string: "https://cinevideos.b-cdn.net/videos/thekingsman/thekingsman.m3u8")!
                let dummyResponse = APIResponse(
                    status: true,
                    message: "Payment Record Verified",
                    isBoughtData: IsBoughtData(videoUrl: "https://cinevideos.b-cdn.net/videos/thekingsman/thekingsman.m3u8")
                )
                eventPublisher.send(.success(videoURL: dummyURL, response: dummyResponse))
                
//                let convertedError = convertError(error)
//                loadingState = .error(convertedError)
//                eventPublisher.send(.error(convertedError))
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
