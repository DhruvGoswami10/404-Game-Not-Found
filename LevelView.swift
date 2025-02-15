import SwiftUI

struct LevelView: View {
    @EnvironmentObject private var levelManager: LevelManager
    let level: Int
    
    var body: some View {
        switch level {
        case 1:
            Level1()
                .environmentObject(levelManager)
        case 2:
            Level2()
                .environmentObject(levelManager)
        case 3:
            Level3()
                .environmentObject(levelManager)
        case 4:
            Level4()
                .environmentObject(levelManager)
        default:
            defaultLevelView
        }
    }
    
    private var defaultLevelView: some View {
        ZStack {
            // Temporary background color for testing
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Level \(level)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                // Back button
                Button("Back to Map") {
                    withAnimation {
                        levelManager.currentState = .progressMap
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                // Temporary complete level button
                Button("Complete Level") {
                    levelManager.unlockNextLevel()
                    withAnimation {
                        levelManager.currentState = .progressMap
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}

#Preview {
    LevelView(level: 1)
        .environmentObject(LevelManager())
}
