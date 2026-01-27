//
//  Direction.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import Foundation

enum Direction: String, CaseIterable {
    case north = "N"
    case south = "S"
    case west  = "W"
    case east  = "E"
    
    var dx: Int {
        switch self {
        case .west:
            return 1
        case .east:
            return -1
        default:
            return 0
        }
    }
    
    var dy: Int {
        switch self {
        case .north:
            return 1
        case .south:
            return -1
        default:
            return 0
        }
    }
}
