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
    private let viewModel = GameViewModel(size: 5)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        viewModel.delegate = self
        viewModel.start()
    }
    
    private func setupUI() {
        navigationItem.title = "Crystals & Dragons"
        
        view.backgroundColor = .systemBackground
        textView.isEditable = false
        inputField.placeholder = "Enter command"
        inputField.addTarget(self, action: #selector(sendCommand), for: .editingDidEndOnExit)
        
        let stack = UIStackView(arrangedSubviews: [textView, inputField])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            //stack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -36)
        ])
    }
    
    @objc private func sendCommand() {
        guard let text = inputField.text else {
            return
        }
        
        viewModel.send(command: text)
        inputField.text = ""
    }
    
    private func append(_ text: String) {
        textView.text += "\n" + text
    }
}

extension GameViewController: GameViewModelDelegate {
    func gameViewModel(_ viewModel: GameViewModel, didProduce output: String) {
        append(output)
    }
}
