import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var levelManager: LevelManager
    @State private var showQuitMessage = false
    @State private var startHovered = false
    @State private var optionsHovered = false
    @State private var quitHovered = false
    @State private var glitchOffset = CGSize.zero
    @State private var glitchScale = 1.0
    @State private var glitchOpacity = 1.0
    @State private var glitchRotation = 0.0
    
    // Timer to trigger glitch effect
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    private let quitMessages = [
        "Nah you for real?!",
        "You can't be serious",
        "Girl? ain't no way!",
        "Already giving up?",
        "That's kinda weak ngl",
        "Imagine quitting in a troll game. Couldn't be me.",
        "Oh, you thought this was optional?",
        "Go ahead. I'll just judge you silently.",
        "We both know you'll come back."
    ]
    
    var body: some View {
        Group {
            switch levelManager.currentState {
            case .mainMenu:
                MainMenuView()
            case .progressMap:
                ProgressMap()
            case .level(let level):
                LevelView(level: level)
            case .secretLevel:
                SecretLevel()
                    .environmentObject(levelManager)
            }
        }
    }
}

// Create a separate view for the main menu content
struct MainMenuView: View {
    @EnvironmentObject private var levelManager: LevelManager
    @State private var showQuitMessage = false
    @State private var startHovered = false
    @State private var optionsHovered = false
    @State private var quitHovered = false
    @State private var glitchOffset = CGSize.zero
    @State private var glitchScale = 1.0
    @State private var glitchOpacity = 1.0
    @State private var glitchRotation = 0.0
    
    // Timer to trigger glitch effect
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    private let quitMessages = [
        "Nah you for real?!",
        "You can't be serious",
        "Girl? ain't no way!",
        "Already giving up?",
        "That's kinda weak ngl",
        "Imagine quitting in a troll game. Couldn't be me.",
        "Oh, you thought this was optional?",
        "Go ahead. I'll just judge you silently.",
        "We both know you'll come back."
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Image("mainBackground")
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height) // Adjust size
                    .scaledToFill() // or .scaledToFit() for different scaling behavior
                    .offset(x: 0, y: 0) // Adjust position if needed
                    .clipped() // Optional: clips the image to the frame
                
                // 404 Logo with glitch effect
                Image("404 logo")
                    .resizable()
                    .frame(width: 300, height: 110) // Adjust size here
                    .offset(y: -200) // Adjust vertical position here
                    .offset(glitchOffset)
                    .scaleEffect(glitchScale)
                    .opacity(glitchOpacity)
                    .rotationEffect(.degrees(glitchRotation))
                    .zIndex(1) // Add this
                    .onReceive(timer) { _ in
                        glitchEffect()
                    }
                
                VStack(spacing: 20) {
                    // Start Button
                    Image("start")
                        .resizable()
                        .frame(width: 310, height: 50)
                        .scaleEffect(startHovered ? 1.1 : 1.0)
                        .onHover { isHovered in
                            startHovered = isHovered
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                levelManager.currentState = .progressMap
                            }
                        }
                    
                    // Options Button
                    Image("options")
                        .resizable()
                        .frame(width: 310, height: 50)
                        .scaleEffect(optionsHovered ? 1.1 : 1.0)
                        .onHover { isHovered in
                            optionsHovered = isHovered
                        }
                        .onTapGesture {
                            // Handle options action
                        }
                    
                    // Quit Button
                    Image("quit")
                        .resizable()
                        .frame(width: 300, height: 60)
                        .offset(x: 0, y: 60)
                        .scaleEffect(quitHovered ? 1.1 : 1.0)
                        .onHover { isHovered in
                            quitHovered = isHovered
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showQuitMessage = true
                                // Auto-hide after 2 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showQuitMessage = false
                                    }
                                }
                            }
                        }
                }
                .offset(y: 50) // Adjust this value to move all buttons up or down
                
                // Quit Message
                if showQuitMessage {
                    Text(quitMessages.randomElement() ?? "Nah you for real?!")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.8))
                                .stroke(Color.red, lineWidth: 2)
                        )
                        .position(x: geometry.size.width / 2, 
                                y: geometry.size.height * 0.3)  // Use absolute positioning
                        .zIndex(2)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showQuitMessage = false
                            }
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func glitchEffect() {
        // Sequence of rapid glitch animations
        withAnimation(.linear(duration: 0.05)) {
            glitchOffset = CGSize(width: CGFloat.random(in: -10...10),
                                height: CGFloat.random(in: -10...10))
            glitchScale = Double.random(in: 0.95...1.05)
            glitchOpacity = Double.random(in: 0.8...1)
            glitchRotation = Double.random(in: -2...2)
        }
        
        // Reset after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.05)) {
                glitchOffset = .zero
                glitchScale = 1.0
                glitchOpacity = 1.0
                glitchRotation = 0
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LevelManager())  // Add environment object to preview
}


