//
//  GameEngine.swift
//  Crystals&Dragons
//
//  Created by Славка Корн on 20.01.2026.
//

import Foundation

final class GameEngine {
    private let maze: Maze
    private let player: Player
    
    private(set) var isGameOver = false
    
    private var previousPosition: (x: Int, y: Int)?
    private var monsterEncounterStart: Date?
    
    init(size: Int) {
        maze = MazeGenerator().generate(size: size)
        player = Player(x: 0, y: 0, steps: size * size * 2)
    }
    
    func currentRoomDescription() -> String {
        guard let room = maze.room(at: player.x, y: player.y) else { return "" }
        
        if case let .dark(isLit) = room.type,
           !isLit,
           !player.has(.torchlight) {
            return "Can’t see anything in this dark place!"
        }
        
        let goldDescription = room.gold.map {
            "gold (\($0.amount) coins)"
        } ?? ""
        
        var description =  """
              You are in the room [\(room.x),\(room.y)].
              There are \(room.doors.count) doors: \(room.doors.map { $0.rawValue }.joined(separator: ", "))
              Items in the room: \(room.items.map { $0.type.rawValue }.joined(separator: ", "))
              Steps left: \(player.stepsLeft)
              Items in the room: \(room.items.map { $0.type.rawValue }.joined(separator: ", ")) \(goldDescription)
              """
        
        if let monster = room.monster {
            description += "\nThere is an evil \(monster.name) in the room!"
        }
        
        return description
    }
    
    func handle(command: String) -> String {
        if let start = monsterEncounterStart,
           let room = maze.room(at: player.x, y: player.y),
           room.monster != nil {
            
            let elapsed = Date().timeIntervalSince(start)
            
            if elapsed > 5 {
                applyMonsterPenalty()
                monsterEncounterStart = nil
                return "The monster attacked you!"
            }
        }
        
        guard !isGameOver else {
            return "Game over."
        }
        
        player.stepsLeft -= 1
        if player.stepsLeft <= 0 {
            isGameOver = true
            return "You died of hunger. Game over."
        }
        
        let parts = command.split(separator: " ")
        
        if let room = maze.room(at: player.x, y: player.y),
           case let .dark(isLit) = room.type,
           !isLit,
           !player.has(.torchlight) {
            
            let allowedMoves = ["N", "S", "E", "W"]
            if !allowedMoves.contains(command) {
                return "It is too dark to do that."
            }
        }
        
        switch parts.first {
        case "N", "S", "W", "E":
            guard let direction = Direction(rawValue: String(parts[0])) else {
                return "Invalid direction."
            }
            return move(direction)
        case "get":
            guard parts.count > 1 else {
                return "Get what?"
            }
            return pickup(String(parts[1]))
        case "drop":
            guard parts.count > 1 else {
                return "Drop what?"
            }
            return drop(String(parts[1]))
        case "open":
            return openChest()
        case "eat":
            guard parts.count > 1 else {
                return "Eat what?"
            }
            return eat(String(parts[1]))
        case "fight":
            return fight()
        case "get" where  parts.count > 1 && parts[1] == "gold":
            return pickupGold()
        default:
            return "Unknown command"
        }
    }
    
    private func move(_ direction: Direction) -> String {
        guard let room = maze.room(at: player.x, y: player.y),
              room.doors.contains(direction)
        else {
            return "No door there."
        }
        
        previousPosition = (player.x, player.y)
        
        player.x += direction.dx
        player.y += direction.dy
        
        if let room = maze.room(at: player.x, y: player.y),
           room.monster != nil {
            monsterEncounterStart = Date()
        }
        
        return currentRoomDescription()
    }
    
    private func pickup(_ itemName: String) -> String {
        guard var room = maze.room(at: player.x, y: player.y),
              let index = room.items.firstIndex(where: { $0.type.rawValue == itemName }),
              room.items[index].type != .chest
        else {
            return "Cannot pick that."
        }
        
        player.inventory.append(room.items.remove(at: index))
        maze.updateRoom(room)
        return "Picked up \(itemName)."
    }
    
    private func drop(_ itemName: String) -> String {
        guard let index = player.inventory.firstIndex(where: { $0.type.rawValue == itemName }),
              var room = maze.room(at: player.x, y: player.y)
        else {
            return "You don't have that."
        }
        
        let item = player.inventory.remove(at: index)
        room.items.append(item)
        
        if item.type == .torchlight,
           case .dark = room.type {
            room.type = .dark(isLit: true)
        }
        
        maze.updateRoom(room)
        
        return "Dropped \(itemName)."
    }
    
    private func openChest() -> String {
        guard player.has(.key),
              let room = maze.room(at: player.x, y: player.y),
              room.items.contains(where: { $0.type == .chest })
        else { return "You need a key." }
        
        isGameOver = true
        return "You opened the chest and found the Holy Grail! You win!"
    }
    
    private func eat(_ itemName: String) -> String {
        guard let index = player.inventory.firstIndex(where: { $0.type.rawValue == itemName }),
              player.inventory[index].type == .food
        else {
            return "You can't eat that."
        }
        
        player.inventory.remove(at: index)
        player.stepsLeft += 5
        
        return "You ate some food. Steps increased!"
    }
    
    private func resolveMonsterInteraction(successCommand: Bool) -> String {
        let roll = Int.random(in: 1...3)
        reduceHealth(by: 0.1)
        
        if roll == 1 {
            rollbackPlayer()
            return "The monster injured you and pushed you back!"
        }
        
        if roll == 2 {
            return successCommand
            ? "You succeeded but were injured!"
            : "You failed and were injured!"
        }
        
        return successCommand
        ? "You succeeded without any damage!"
        : "You escaped unharmed!"
    }
    
    private func reduceHealth(by percent: Double) {
        player.stepsLeft = Int(Double(player.stepsLeft) * (1.0 - percent))
    }
    
    private func rollbackPlayer() {
        if let previous = previousPosition {
            player.x = previous.x
            player.y = previous.y
        }
    }
    
    private func applyMonsterPenalty() {
        reduceHealth(by: 0.1)
        rollbackPlayer()
    }
    
    private func fight() -> String {
        guard player.has(.sword) else {
            return "You have no weapon."
        }
        
        guard var room = maze.room(at: player.x, y: player.y),
              room.monster != nil
        else {
            return "There is nothing to fight here."
        }
        
        let outcome = Int.random(in: 0..<3)
        
        switch outcome {
        case 0:
            reduceHealth(by: 0.1)
            rollbackPlayer()
            return "The monster wounded you and threw you back!"
            
        case 1:
            reduceHealth(by: 0.1)
            room.monster = nil
            maze.updateRoom(room)
            return "You killed the monster, but got hurt."
            
        default:
            room.monster = nil
            maze.updateRoom(room)
            return "You killed the monster without a scratch!"
        }
    }
    
    private func pickupGold() -> String {
        guard var room = maze.room(at: player.x, y: player.y),
              let gold = room.gold
        else {
            return "No gold here."
        }
        
        player.coins += gold.amount
        room.gold = nil
        maze.updateRoom(room)
        
        return "You picked up \(gold.amount) gold coins."
    }
}
