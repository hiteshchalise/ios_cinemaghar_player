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
}

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
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.setTitleColor(configuration.loadingIndicatorColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        return button
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
        
        // Add loading indicator
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add loading label if provided
        if let loadingLabel = loadingLabel {
            view.addSubview(loadingLabel)
            NSLayoutConstraint.activate([
                loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
                loadingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
                loadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
            ])
        }
        
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
    }
    
    // MARK: - Actions
    @objc private func dismissButtonTapped() {
        delegate?.introViewControllerDidRequestDismiss(self)
    }
}
