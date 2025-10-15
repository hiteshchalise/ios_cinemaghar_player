//
//  IntroView.swift
//  CinemagharPlayerTest
//
//  Created by Hitesh Chalise on 14/10/2025.
//
import SwiftUI


struct IntroView: View {
    @StateObject private var viewModel: IntroViewModel
    let onDismiss: () -> Void
    let onSuccess: (URL, APIResponse) -> Void
    
    init(
        configuration: VideoPlayerConfiguration,
        onDismiss: @escaping () -> Void,
        onSuccess: @escaping (URL, APIResponse) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: IntroViewModel(configuration: configuration))
        self.onDismiss = onDismiss
        self.onSuccess = onSuccess
    }
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                switch viewModel.loadingState {
                case .loading:
                    loadingContent
                case .error(let error):
                    errorContent(error)
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Text("✕")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
        .onAppear {
            viewModel.loadVideoData()
        }
        .onDisappear {
            viewModel.cancelLoad()
        }
        .onReceive(viewModel.eventPublisher) { event in
            handleViewModelEvent(event)
        }
    }
    
    // MARK: - Event Handler
    private func handleViewModelEvent(_ event: IntroViewModelEvent) {
        switch event {
        case .success(let videoURL, let response):
            print("handling success from viewmodel event")
            onSuccess(videoURL, response)
        case .error(let error):
            // Handle error event if needed
            print("❌ Error event received: \(error)")
        }
    }
    
    @ViewBuilder
    private var loadingContent: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)

        Text("loading")
            .font(.system(size: 16))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
        
    }
    
    @ViewBuilder
    private func errorContent(_ error: VideoPlayerError) -> some View {
        Text(error.localizedDescription)
            .font(.system(size: 16))
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        
        Button(action: viewModel.retry) {
            Text("Retry")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
    }
}
