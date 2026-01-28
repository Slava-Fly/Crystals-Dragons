//
//  Room.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import Foundation

enum RoomType {
    case normal
    case dark(isLit: Bool)
}

struct Room {
    let x: Int
    let y: Int
    
    var isActive: Bool
    var doors: Set<Direction>
    var items: [Item]
    var type: RoomType
    var monster: Monster?
    var gold: Gold?
}
