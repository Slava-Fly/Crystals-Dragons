//
//  MazeGenerator.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import Foundation
import UIKit

final class MazeGenerator {
    func generate(roomCount: Int) -> Maze {
        let width = Int(ceil(sqrt(Double(roomCount))))
        let height = Int(ceil(Double(roomCount) / Double(width)))
        
        // Создание сетки
        var rooms: [[Room]] = []
        var index = 0
        
        for y in 0..<height {
            var row: [Room] = []
            for x in 0..<width {
                let isActive = index < roomCount
                
                row.append(
                    Room(
                        x: x,
                        y: y,
                        isActive: isActive,
                        doors: [],
                        items: [],
                        type: .normal,
                        monster: nil,
                        gold: nil
                    )
                )
                index += 1
            }
            rooms.append(row)
        }
        
        // depthFirstSearch генерация лабиринта
        var visited = Set<String>()
        
        func key(_ x: Int, _ y: Int) -> String {
            "\(x)-\(y)"
        }
        
        func depthFirstSearch(x: Int, y: Int) {
            visited.insert(key(x, y))
            
            for dir in Direction.allCases.shuffled() {
                let nx = x + dir.dx
                let ny = y + dir.dy
                
                guard nx >= 0, ny >= 0, nx < width, ny < height else {
                    continue
                }
                
                guard rooms[ny][nx].isActive else {
                    continue
                }
                
                guard !visited.contains(key(nx, ny)) else {
                    continue
                }
                
                rooms[y][x].doors.insert(dir)
                rooms[ny][nx].doors.insert(opposite(dir))
                depthFirstSearch(x: nx, y: ny)
            }
        }
        
        depthFirstSearch(x: 0, y: 0)
        
        // Список активных комнат кроме старта
        let activeCoords: [(x: Int, y: Int)] = rooms
            .flatMap { $0 }
            .filter { $0.isActive && !($0.x == 0 && $0.y == 0) }
            .map { ($0.x, $0.y) }
        
        // Размещение сундука
        guard let chestCoord = activeCoords.randomElement() else {
            fatalError("No room for chest")
        }
        rooms[chestCoord.y][chestCoord.x].items.append(Item(type: .chest))
        
        // Размещение ключа
        let keyRooms = activeCoords.filter { $0 != chestCoord }
        guard let keyCoord = keyRooms.randomElement() else {
            fatalError("No room for key")
        }
        rooms[keyCoord.y][keyCoord.x].items.append(Item(type: .key))
        
        // Тёмные комнаты
        for room in rooms.flatMap({ $0 }) where room.isActive {
            let isCritical =
            (room.x == 0 && room.y == 0) ||
            (room.x == chestCoord.x && room.y == chestCoord.y) ||
            (room.x == keyCoord.x && room.y == keyCoord.y)
            
            if !isCritical && Double.random(in: 0...1) < 0.2 {
                rooms[room.y][room.x].type = .dark(isLit: false)
            }
        }
        
        // Размещение факела
        let torchRooms = activeCoords.filter {
            $0 != chestCoord &&
            $0 != keyCoord &&
            rooms[$0.y][$0.x].monster == nil
        }
        
        if let torchCoord = torchRooms.randomElement() {
            rooms[torchCoord.y][torchCoord.x].items.append(Item(type: .torchlight))
        }
        
        // Размещение еды
        for _ in 0..<(roomCount / 2) {
            if let coord = activeCoords.randomElement() {
                rooms[coord.y][coord.x].items.append(Item(type: .food))
            }
        }
        
        // Размещение меча
        if let swordCoord = activeCoords.filter({ $0 != chestCoord }).randomElement() {
            rooms[swordCoord.y][swordCoord.x].items.append(Item(type: .sword))
        }
        
        // Размещение золота
        for _ in 0..<(roomCount / 2) {
            if let coord = activeCoords.randomElement() {
                let amount = Int.random(in: 5...30)
                rooms[coord.y][coord.x].gold = Gold(amount: amount)
            }
        }
        
        // Размещение монстров
        let monsterNames = ["dragon", "goblin", "orc"]
        
        for _ in 0..<(roomCount / 2) {
            guard let coord = activeCoords.randomElement() else {
                continue
            }
            
            let isCritical =
            (coord.x == 0 && coord.y == 0) ||
            (coord.x == chestCoord.x && coord.y == chestCoord.y) ||
            (coord.x == keyCoord.x && coord.y == keyCoord.y)
            
            if rooms[coord.y][coord.x].monster == nil && !isCritical {
                rooms[coord.y][coord.x].monster = Monster(name: monsterNames.randomElement()!)
            }
        }
        
        for room in rooms.flatMap({ $0 }) where room.isActive {
            if !room.items.isEmpty || room.monster != nil || room.gold != nil {
                print("Room [\(room.x),\(room.y)] items: \(room.items), monster: \(room.monster?.name ?? "none"), gold: \(room.gold?.amount ?? 0)")
            }
        }
        
        return Maze(width: width, height: height, rooms: rooms)
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
