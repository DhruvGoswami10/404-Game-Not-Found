import SwiftUI

enum GameState {
    case mainMenu
    case progressMap
    case level(Int)
    case secretLevel  // Add this new case
}

class LevelManager: ObservableObject {
    @Published var currentState: GameState = .mainMenu
    @Published var unlockedLevels: Set<Int> = [1]
    
    // Add persistent storage for death counts and notes
    @Published var deathCounts: [Int: Int] = [:]
    @Published private var allDeathNotes: [(note: String, position: CGPoint, rotation: Double)] = []
    @Published private var totalDeathCount: Int = 0
    
    // Track current death state
    private var isProcessingDeath = false
    
    func navigateToLevel(_ level: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = .level(level)
        }
    }
    
    func unlockNextLevel() {
        if let currentLevel = getCurrentLevel() {
            unlockedLevels.insert(currentLevel + 1)
        }
    }
    
    func getCurrentLevel() -> Int? {
        if case let .level(level) = currentState {
            return level
        }
        return nil
    }
    
    func isLevelUnlocked(_ level: Int) -> Bool {
        if level <= 0 { return false }
        if level == 1 { return true }
        return unlockedLevels.contains(level)
    }
    
    func getDeathCount(for level: Int) -> Int {
        return totalDeathCount
    }
    
    func incrementDeathCount(for level: Int) {
        if !isProcessingDeath {
            isProcessingDeath = true
            totalDeathCount += 1
            deathCounts[level] = (deathCounts[level] ?? 0) + 1
        }
    }
    
    func getDeathNotes(for level: Int) -> [(note: String, position: CGPoint, rotation: Double)] {
        List {
            /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Content@*/Text("Content")/*@END_MENU_TOKEN@*/
        }   
        return allDeathNotes
    }
    
    func addDeathNote(for level: Int, note: String, position: CGPoint, rotation: Double) {
        guard isProcessingDeath else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            allDeathNotes.append((note: note, position: position, rotation: rotation))
            isProcessingDeath = false  // Reset after adding note
        }
    }

    func getTotalDeathCount() -> Int {
        return totalDeathCount
    }
}

