//
//  IntroViewController.swift
//  CinemagharPlayerSDK
//
//  Created by Hitesh Chalise on 23/09/2025.
//

import UIKit

@MainActor
protocol IntroViewControllerDelegate: AnyObject {
    func introViewControllerDidRequestDismiss(_ controller: IntroViewController)
    func introViewControllerDidRequestRetry()
}

// MARK: - IntroViewController
internal class IntroViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: IntroViewControllerDelegate?
    private let configuration: VideoPlayerConfiguration
    
    // MARK: - UI Components
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = configuration.loadingIndicatorColor
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var loadingLabel: UILabel? = {
        guard let loadingText = configuration.loadingText else { return nil }
        
        let label = UILabel()
        label.text = loadingText
        label.textColor = configuration.loadingIndicatorColor
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.setTitleColor(configuration.loadingIndicatorColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Initialization
    init(configuration: VideoPlayerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startLoading()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = configuration.introBackgroundColor
        
        // Setup content stack
        view.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(loadingIndicator)
        if let loadingLabel = loadingLabel {
            contentStackView.addArrangedSubview(loadingLabel)
        }
        contentStackView.addArrangedSubview(errorLabel)
        contentStackView.addArrangedSubview(retryButton)
        
        NSLayoutConstraint.activate([
            contentStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
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
    
    private func startLoading() {
        loadingIndicator.startAnimating()
        errorLabel.isHidden = true
        retryButton.isHidden = true
        loadingLabel?.isHidden = false
    }
    
    // MARK: - Public Methods
    func showError(_ error: VideoPlayerError) {
        print("🔴 IntroViewController showing error: \(error)")
        
        loadingIndicator.stopAnimating()
        loadingLabel?.isHidden = true
        
        errorLabel.text = error.localizedDescription
        errorLabel.isHidden = false
        retryButton.isHidden = false
    }
    
    // MARK: - Actions
    @objc private func dismissButtonTapped() {
        print("👆 Dismiss button tapped")
        print("   Delegate: \(delegate != nil)")
        print("   NavigationController: \(navigationController != nil)")
        print("   PresentingViewController: \(presentingViewController != nil)")
        
        // Notify delegate first (for cleanup)
        delegate?.introViewControllerDidRequestDismiss(self)
        
        // Dismiss the navigationController that's presenting this VC
        // Use presentingViewController to dismiss from the presenter's side
        if let navController = navigationController {
            navController.dismiss(animated: true, completion: nil)
        } else if let presenter = presentingViewController {
            presenter.dismiss(animated: true, completion: nil)
        } else {
            print("⚠️ Cannot find presenting view controller")
        }
    }
    
    @objc private func retryButtonTapped() {
        print("🔄 Retry button tapped")
        delegate?.introViewControllerDidRequestRetry()
    }
}
