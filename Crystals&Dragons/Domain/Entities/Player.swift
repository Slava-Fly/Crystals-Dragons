//
//  Player.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import Foundation

final class Player {
    var x: Int
    var y: Int
    var inventory: [Item] = []
    var stepsLeft: Int
    var coins: Int = 0
    
    init(x: Int, y: Int, steps: Int) {
        self.x = x
        self.y = y
        self.stepsLeft = steps
    }
    
    func has(_ type: ItemType) -> Bool {
        inventory.contains {
            $0.type == type
        }
    }
}
