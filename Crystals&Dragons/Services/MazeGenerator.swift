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
        var rooms = Array(
            repeating: Array(
                repeating: Room(x: 0, y: 0, doors: [], items: [], type: .normal),
                count: size
            ),
            count: size
        )
        
        for y in 0..<size {
            for x in 0..<size {
                rooms[y][x] = Room(x: x, y: y, doors: [], items: [], type: .normal)
            }
        }
        
        // DFS лабиринт
        var visited = Array(repeating: Array(repeating: false, count: size), count: size)
        
        func depthFirstSearch(x: Int, y: Int) {
            visited[y][x] = true
            let directions = Direction.allCases.shuffled()
            
            for direction in directions {
                let nx = x + direction.dx
                let ny = y + direction.dy
                
                guard nx >= 0, ny >= 0, nx < size, ny < size else { continue }
                guard !visited[ny][nx] else { continue }
                
                rooms[y][x].doors.insert(direction)
                rooms[ny][nx].doors.insert(opposite(direction))
                depthFirstSearch(x: nx, y: ny)
            }
        }
        
        depthFirstSearch(x: 0, y: 0)
        
        // Список координат кроме старта
        var allCoords: [(x: Int, y: Int)] = []
        for y in 0..<size {
            for x in 0..<size where !(x == 0 && y == 0) {
                allCoords.append((x, y))
            }
        }

        // Размещение сундука
        guard let chestCoord = allCoords.randomElement() else {
            fatalError("Failed to pick chest room")
        }
        rooms[chestCoord.y][chestCoord.x].items.append(Item(type: .chest))

        // Размещение ключа
        let possibleKeyRooms = allCoords.filter {
            !($0.x == chestCoord.x && $0.y == chestCoord.y)
        }

        guard let keyCoord = possibleKeyRooms.randomElement() else {
            fatalError("Failed to pick key room")
        }
        rooms[keyCoord.y][keyCoord.x].items.append(Item(type: .key))
        
        // Тёмные комнаты
        for y in 0..<size {
            for x in 0..<size {
                let isCritical =
                    (x == 0 && y == 0) ||
                    (x == chestCoord.x && y == chestCoord.y) ||
                    (x == keyCoord.x && y == keyCoord.y)
                
                let isDark = Bool.random() && !isCritical
                rooms[y][x].type = isDark ? .dark(isLit: false) : .normal
            }
        }
        
        // Размещение еды
        for _ in 0..<(size / 2) {
            let y = Int.random(in: 0..<size)
            let x = Int.random(in: 0..<size)
            rooms[y][x].items.append(Item(type: .food))
        }
        
        // Размещение меча
        let swordCoord = allCoords
            .filter { !($0.x == chestCoord.x && $0.y == chestCoord.y) }
            .randomElement()!
        rooms[swordCoord.y][swordCoord.x].items.append(Item(type: .sword))
        
        // Развиещение монстров
        let monsterNames = ["dragon", "goblin", "orc"]
        
        for _ in 0..<(size / 2) {
            let y = Int.random(in: 0..<size)
            let x = Int.random(in: 0..<size)
            
            let isCritical =
                (x == 0 && y == 0) ||
                (x == chestCoord.x && y == chestCoord.y) ||
                (x == keyCoord.x && y == keyCoord.y)
            
            if rooms[y][x].monster == nil && !isCritical {
                rooms[y][x].monster = Monster(name: monsterNames.randomElement()!)
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
