//
//  MazeGenerator.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import Foundation
import UIKit

final class MazeGenerator {
    
    func generate(size: Int) -> Maze {
        var rooms = Array(repeating:
                            Array(repeating:
                                    Room(x: 0, y: 0, doors: [], items: [], type: .normal),
                                  count: size),
                          count: size
        )
        
        for y in 0..<size {
            for x in 0..<size {
                rooms[y][x] = Room(x: x, y: y, doors: [], items: [], type: .normal)
            }
        }
        
        var visited = Array(repeating: Array(repeating: false, count: size), count: size)
        
        func depthFirstSearch(x: Int, y: Int) {
            visited[y][x] = true
            
            let directions = Direction.allCases.shuffled()
            
            for dir in directions {
                let nx = x + dir.dx
                let ny = y + dir.dy
                
                guard nx >= 0, ny >= 0, nx < size, ny < size else { continue }
                guard !visited[ny][nx] else { continue }
                
                rooms[y][x].doors.insert(dir)
                rooms[ny][nx].doors.insert(opposite(dir))
                depthFirstSearch(x: nx, y: ny)
            }
        }
        
        depthFirstSearch(x: 0, y: 0)
        
        for y in 0..<size {
            for x in 0..<size {
                let isDark = Bool.random() && !(x == 0 && y == 0)
                rooms[y][x].type = isDark ? .dark(isLit: false) : .normal
            }
        }
        
        // 1. Размещаем сундук
        rooms[size - 1][size - 1].items.append(Item(type: .chest))
        
        // 2. Размещаем ключ
        if let rowIndex = rooms.indices.randomElement(),
           let colIndex = rooms[rowIndex].indices.randomElement() {
            rooms[rowIndex][colIndex].items.append(Item(type: .key))
        }
        
        // 3. Размещаем еду
        for _ in 0..<(size / 2) {
            let y = Int.random(in: 0..<size)
            let x = Int.random(in: 0..<size)
            
            rooms[y][x].items.append(Item(type: .food))
        }
        
        // 4. Размещаем меч
        rooms[size / 2][size / 2].items.append(Item(type: .sword))
        
        let monsterNames = ["dragon", "goblin", "orc"]
        
        for _ in 0..<(size / 2) {
            let y = Int.random(in: 0..<size)
            let x = Int.random(in: 0..<size)
            
            if rooms[y][x].monster == nil && !(x == 0 && y == 0) {
                rooms[y][x].monster = Monster(name: monsterNames.randomElement() ?? "")
            }
        }
        
        return Maze(width: size, height: size, rooms: rooms)
    }
    
    private func opposite(_ direction: Direction) -> Direction {
        switch direction {
        case .north:
            return .south
        case .south:
            return .north
        case .west:
            return .east
        case .east:
            return .west
        }
    }
}
