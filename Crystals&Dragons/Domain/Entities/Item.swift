//
//  Item.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import Foundation

enum ItemType: String {
    case key
    case chest
    case grail
    case torchlight
    case food
    case sword
}

struct Item: Equatable {
    let type: ItemType
}
