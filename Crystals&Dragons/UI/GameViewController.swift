//
//  GameViewController.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import UIKit

class GameViewController: UIViewController {
    private let textView = UITextView()
    private let inputField = UITextField()
    private let containerView = UIView()
    private let sendButton = UIButton(type: .system)
    
    private var isGameStarted = false
    private var viewModel: GameViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        promptForMazeSize()
    }
    
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .gameBackground
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func setupUI() {
        navigationItem.title = "Crystals & Dragons"
        
        view.backgroundColor = .gameBackground
        
        containerView.backgroundColor = .gameCard
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        textView.backgroundColor = .clear
        textView.textColor = .gameText
        textView.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        
        inputField.backgroundColor = .gameInput
        inputField.textColor = .white
        inputField.layer.cornerRadius = 10
        inputField.setLeftPaddingPoints(10)
        inputField.attributedPlaceholder = NSAttributedString(
            string: "Enter command",
            attributes: [.foregroundColor: UIColor(white: 1, alpha: 0.5)]
        )
        inputField.addTarget(self, action: #selector(sendCommand), for: .editingDidEndOnExit)
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.backgroundColor = .gameAccent
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 10
        sendButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        sendButton.addTarget(self, action: #selector(sendCommand), for: .touchUpInside)
        
        let inputStack = UIStackView(arrangedSubviews: [inputField, sendButton])
        inputStack.axis = .horizontal
        inputStack.spacing = 10
        inputStack.distribution = .fillProportionally
        
        let mainStack = UIStackView(arrangedSubviews: [textView, inputStack])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            sendButton.widthAnchor.constraint(equalToConstant: 90),
            inputField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func promptForMazeSize() {
        let alert = UIAlertController(
            title: "Maze size",
            message: "Enter number of rooms",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Number of rooms"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Start", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  let roomCount = Int(text),
                  roomCount > 0 else {
                self?.promptForMazeSize()
                return
            }
            self.startGame(with: roomCount)
        })
        present(alert, animated: true)

    }
    
    private func startGame(with roomCount: Int) {
        guard !isGameStarted else {
            return
        }
        isGameStarted = true
        
        viewModel = GameViewModel(roomCount: roomCount)
        
        setupUI()
        
        viewModel.delegate = self
        viewModel.start()
    }
    
    @objc private func sendCommand() {
        guard let text = inputField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        inputField.text = ""
        
        viewModel.send(command: text)
    }
}

// MARK: GameViewModelDelegate
extension GameViewController: GameViewModelDelegate {
    func gameViewModel(_ viewModel: GameViewModel, didProduce output: GameOutput) {
        let attributed = viewModel.attributed(from: output)
        
        let currentText = NSMutableAttributedString(attributedString: textView.attributedText)
        currentText.append(attributed)
        
        textView.attributedText = currentText
        
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            if self.textView.text.count > 0 {
                let location = self.textView.text.count - 1
                let bottom = NSRange(location: location, length: 1)
                
                self.textView.scrollRangeToVisible(bottom)
            }
        }
    }
}
