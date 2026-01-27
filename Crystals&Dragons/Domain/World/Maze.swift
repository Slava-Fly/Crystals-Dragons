//
//  Maze.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import Foundation

final class Maze {
    let width: Int
    let height: Int
    
    private(set) var rooms: [[Room]]
    
    init(width: Int, height: Int, rooms: [[Room]]) {
        self.width = width
        self.height = height
        self.rooms = rooms
    }
    
    func room(at x: Int, y: Int) -> Room? {
        guard x >= 0, y >= 0, x < width, y < height else {
            return nil
        }
        
        return rooms[y][x]
    }
    
    func updateRoom(_ room: Room) {
        rooms[room.y][room.x] = room
    }
}
