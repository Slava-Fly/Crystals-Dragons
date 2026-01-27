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
    
    // Описание комнаты
    func currentRoomDescription() -> GameOutput {
        guard let room = maze.room(at: player.x, y: player.y) else {
            return GameOutput(text: "", style: .normal)
        }
        
        if case let .dark(isLit) = room.type,
           !isLit,
           !player.has(.torchlight) {
            return GameOutput(
                text: "Can’t see anything in this dark place!",
                style: .info
            )
        }
        
        let goldDescription = room.gold.map {
            "gold (\($0.amount) coins)"
        } ?? ""
        
        // Основной текст комнаты
        var description = """
    You are in the room [\(room.x),\(room.y)].
    There are \(room.doors.count) doors: \(room.doors.map { $0.rawValue }.joined(separator: ", "))
    Items in the room: \(room.items.map { $0.type.rawValue }.joined(separator: ", ")) \(goldDescription)
    Steps left: \(player.stepsLeft)
    """
        
        if let monster = room.monster {
            description += "\nThere is an evil \(monster.name) in the room!"
            return GameOutput(text: description, style: .danger)
        }
        
        return GameOutput(text: description, style: .normal)
    }
    
    // Обработка команды игрока
    func handle(command rawInput: String) -> GameOutput {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = input.split(separator: " ").map { String($0) }
        
        // Таймер атаки монстра
        if let start = monsterEncounterStart,
           let room = maze.room(at: player.x, y: player.y),
           room.monster != nil {
            
            let elapsed = Date().timeIntervalSince(start)
            
            if elapsed > 5 {
                applyMonsterPenalty()
                monsterEncounterStart = nil
                return GameOutput(text: "The monster attacked you!",style: .danger)
            }
        }
        
        guard !isGameOver else {
            return GameOutput(text: "Game over.",style: .danger)
        }
        
        player.stepsLeft -= 1
        if player.stepsLeft <= 0 {
            isGameOver = true
            return GameOutput(text: "You died of hunger. Game over.",style: .danger)
        }
        
        // Тёмная комната блокирует все кроме движения
        if let room = maze.room(at: player.x, y: player.y),
           case let .dark(isLit) = room.type,
           !isLit,
           !player.has(.torchlight) {
            if !["n","s","e","w"].contains(input) {
                return GameOutput(text: "It is too dark to do that.",style: .warning)
            }
        }
        
        guard !parts.isEmpty else {
            return GameOutput(text: "Unknown command", style: .warning)
        }
        
        switch parts[0] {
        case "n":
            return move(.north)
        case "s":
            return move(.south)
        case "e":
            return move(.east)
        case "w":
            return move(.west)
            
        case "get":
            guard parts.count > 1 else {
                return GameOutput(text: "Get what?", style: .warning)
            }
            
            let itemName = parts[1]
            
            if itemName == "gold" {
                return pickupGold()
            }
            return pickup(itemName)
            
        case "drop":
            guard parts.count > 1 else {
                return GameOutput(text: "Drop what?", style: .warning)
            }
            return drop(parts[1])
            
        case "eat":
            guard parts.count > 1 else {
                return GameOutput(text: "Eat what?", style: .warning)
            }
            return eat(parts[1])
            
        case "open":
            return openChest()
            
        case "fight":
            return fight()
            
        default:
            return GameOutput(text: "Unknown command", style: .warning)
        }
    }
    
    private func move(_ direction: Direction) -> GameOutput {
        guard let room = maze.room(at: player.x, y: player.y),
              room.doors.contains(direction) else {
            return GameOutput(text: "No door there.", style: .warning)
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
    
    private func pickup(_ itemName: String) -> GameOutput {
        guard var room = maze.room(at: player.x, y: player.y),
              let index = room.items.firstIndex(where: { $0.type.rawValue == itemName }),
              room.items[index].type != .chest
        else {
            return GameOutput(text: "Cannot pick that.", style: .warning)
        }
        
        player.inventory.append(room.items.remove(at: index))
        maze.updateRoom(room)
        return GameOutput(text: "Picked up \(itemName).", style: .success)
    }
    
    private func drop(_ itemName: String) -> GameOutput {
        guard let index = player.inventory.firstIndex(where: { $0.type.rawValue == itemName }),
              var room = maze.room(at: player.x, y: player.y)
        else {
            return GameOutput(text: "You don't have that.", style: .warning)
        }
        
        let item = player.inventory.remove(at: index)
        room.items.append(item)
        
        if item.type == .torchlight,
           case .dark = room.type {
            room.type = .dark(isLit: true)
        }
        
        maze.updateRoom(room)
        
        return GameOutput(text: "Dropped \(itemName).", style: .normal)
    }
    
    private func openChest() -> GameOutput {
        guard player.has(.key),
              let room = maze.room(at: player.x, y: player.y),
              room.items.contains(where: { $0.type == .chest })
        else {
            return GameOutput(text: "You need a key.", style: .warning)
        }
        
        isGameOver = true
        return GameOutput(
            text: "You opened the chest and found the Holy Grail! You win!",
            style: .success
        )
    }
    
    private func eat(_ itemName: String) -> GameOutput {
        guard let index = player.inventory.firstIndex(where: { $0.type.rawValue == itemName }),
              player.inventory[index].type == .food
        else {
            return GameOutput(text: "You can't eat that.", style: .warning)
        }
        
        player.inventory.remove(at: index)
        player.stepsLeft += 5
        
        return GameOutput(text: "You ate some food. Steps increased!", style: .success)
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
    
    private func fight() -> GameOutput {
        guard player.has(.sword) else {
            return GameOutput(text: "You have no weapon.", style: .warning)
        }
        
        guard var room = maze.room(at: player.x, y: player.y),
              room.monster != nil
        else {
            return GameOutput(text: "There is nothing to fight here.", style: .warning)
        }
        
        let outcome = Int.random(in: 0..<3)
        
        switch outcome {
        case 0:
            reduceHealth(by: 0.1)
            rollbackPlayer()
            return GameOutput(text: "The monster wounded you and threw you back!", style: .danger)
            
        case 1:
            reduceHealth(by: 0.1)
            room.monster = nil
            maze.updateRoom(room)
            return GameOutput(text: "You killed the monster, but got hurt.", style: .warning)
            
        default:
            room.monster = nil
            maze.updateRoom(room)
            return GameOutput(text: "You killed the monster without a scratch!", style: .success)
        }
    }
    
    private func pickupGold() -> GameOutput {
        guard var room = maze.room(at: player.x, y: player.y),
              let gold = room.gold
        else {
            return GameOutput(text: "No gold here.", style: .warning)
        }
        
        player.coins += gold.amount
        room.gold = nil
        maze.updateRoom(room)
        
        return GameOutput(text: "You picked up \(gold.amount) gold coins.", style: .success)
    }
}




