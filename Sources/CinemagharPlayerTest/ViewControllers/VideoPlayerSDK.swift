//
//  VideoPlayerSDK.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import UIKit
import SwiftUI


// MARK: - VideoPlayerSDK
@MainActor
public class VideoPlayerSDK: UIViewController {
    
    // MARK: - Properties
    public let configuration: VideoPlayerConfiguration
    
    private var introHostingController: UIHostingController<IntroView>?
    
    // MARK: - Initialization
    public init(configuration: VideoPlayerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupIntroView()
    }
    

    // MARK: - Setup
    private func setupIntroView() {
        let introView = IntroView(
            configuration: configuration,
            onDismiss: { [weak self] in
                self?.handleDismiss()
            },
            onSuccess: { [weak self] videoURL, response in
                print("Handling Success")
                self?.handleSuccess(videoURL: videoURL, response: response)
            }
        )
        
        let hostingController = UIHostingController(rootView: introView)
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
        
        self.introHostingController = hostingController
    }
    
    // MARK: - Actions
    private func handleDismiss() {
        print("📱 Dismiss requested")
        if let navController = navigationController {
            navController.dismiss(animated: true, completion: nil)
        } else if let presenter = presentingViewController {
            presenter.dismiss(animated: true, completion: nil)
        } else {
            print("⚠️ Cannot find presenting view controller")
        }
    }
    
    private func handleSuccess(videoURL: URL, response: APIResponse) {
        print("✅ Navigating to player")
        navigateToPlayer(with: videoURL, response: response)
    }
    
    private func navigateToPlayer(with url: URL, response: APIResponse) {
        let playerVC = VideoPlayerViewController(
            videoURL: url,
            configuration: configuration,
            apiResponse: response
        )

        // Present the player in full screen
        playerVC.modalPresentationStyle = .fullScreen

        // Dismiss self first, then present the player from the host context
        if let presentingVC = presentingViewController {
            dismiss(animated: false) {
                presentingVC.present(playerVC, animated: true)
            }
        } else if let nav = navigationController {
            // If inside navigation stack, replace current VC
            var viewControllers = nav.viewControllers
            viewControllers.removeLast()
            viewControllers.append(playerVC)
            nav.setViewControllers(viewControllers, animated: true)
        } else {
            // Fallback (rare): just present normally
            present(playerVC, animated: true)
        }
    }

}
