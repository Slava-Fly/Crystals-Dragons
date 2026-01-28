//
//  GameViewModel.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import UIKit

protocol GameViewModelDelegate: AnyObject {
    func gameViewModel(_ viewModel: GameViewModel, didProduce output: GameOutput)
}

final class GameViewModel {
    let engine: GameEngine
    
    weak var delegate: GameViewModelDelegate?
    
    init(roomCount: Int) {
        engine = GameEngine(roomCount: roomCount)
    }
    
    func start() {
        delegate?.gameViewModel(self, didProduce: engine.currentRoomDescription())
    }
    
    func send(command: String) {
        let result = engine.handle(command: command)
        delegate?.gameViewModel(self, didProduce: result)
    }
    
    func attributed(from output: GameOutput) -> NSAttributedString {
        let color: UIColor
        
        switch output.style {
        case .normal:
            color = .white
        case .danger:
            color = .systemRed
        case .warning:
            color = .systemOrange
        case .success:
            color = .systemGreen
        case .info:
            color = .systemBlue
        }
        
        return NSAttributedString(
            string: output.text + "\n",
            attributes: [.foregroundColor: color]
        )
    }
}
