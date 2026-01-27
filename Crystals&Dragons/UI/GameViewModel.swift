//
//  GameViewModel.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import UIKit

protocol GameViewModelDelegate: AnyObject {
    func gameViewModel(_ viewModel: GameViewModel, didProduce output: String)
}

final class GameViewModel {
    private let engine: GameEngine
    
    weak var delegate: GameViewModelDelegate?
    
    init(size: Int) {
        engine = GameEngine(size: size)
    }
    
    func start() {
        delegate?.gameViewModel(self, didProduce: engine.currentRoomDescription())
    }
    
    func send(command: String) {
        let result = engine.handle(command: command)
        delegate?.gameViewModel(self, didProduce: result)
    }
}
