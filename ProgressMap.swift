import SwiftUI

struct ProgressMap: View {
    @EnvironmentObject private var levelManager: LevelManager
    @State private var level1Hover = false
    @State private var level2Hover = false
    @State private var level3Hover = false
    @State private var level4Hover = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Image("background")
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaledToFill()
                
                // Level buttons in HStack for better hit testing
                HStack(spacing: geometry.size.width * 0.15) {
                    // Level 1
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            levelManager.currentState = .level(1)
                        }
                    }) {
                        Image("level-1")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .scaleEffect(level1Hover ? 1.1 : 1.0)
                            .opacity(levelManager.isLevelUnlocked(1) ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            level1Hover = hover
                        }
                    }
                    
                    // Level 2
                    Button(action: {
                        if levelManager.isLevelUnlocked(2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                levelManager.currentState = .level(2)  // Direct navigation to Level2
                            }
                        }
                    }) {
                        Image("level-2")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .scaleEffect(level2Hover ? 1.1 : 1.0)
                            .opacity(levelManager.isLevelUnlocked(2) ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            level2Hover = hover
                        }
                    }
                    
                    // Level 3
                    Button(action: {
                        if levelManager.isLevelUnlocked(3) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                levelManager.currentState = .level(3)
                            }
                        }
                    }) {
                        Image("level-3")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .scaleEffect(level3Hover ? 1.1 : 1.0)
                            .opacity(levelManager.isLevelUnlocked(3) ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            level3Hover = hover
                        }
                    }
                    
                    // Level 4 button
                    Button(action: {
                        if levelManager.isLevelUnlocked(4) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                levelManager.currentState = .level(4)
                            }
                        }
                    }) {
                        Image("level-4")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .scaleEffect(level4Hover ? 1.1 : 1.0)
                            .opacity(levelManager.isLevelUnlocked(4) ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            level4Hover = hover
                        }
                    }
                    
                    // Remove Level5 button
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ProgressMap()
        .environmentObject(LevelManager())
}
