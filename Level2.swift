import SwiftUI

struct Level2: View {
    @EnvironmentObject private var levelManager: LevelManager
    @State private var playerState: PlayerState = .idle
    @State private var playerFacingRight = true
    
    // Player state
    @State private var playerPosition = CGPoint(x: 130, y: 510) // Adjusted for platform2
    @State private var playerVelocity = CGPoint.zero
    @State private var isOnGround = true
    @State private var isMovingLeft = false
    @State private var isMovingRight = false
    @State private var isDead = false
    @State private var isLevelComplete = false
    
    // Physics constants
    private let gravity: CGFloat = 0.8
    private let jumpForce: CGFloat = -15
    private let moveSpeed: CGFloat = 7
    
    // Platform configurations
    private let platformY: CGFloat = 600  // Only platform2 height
    private let platformHeight: CGFloat = 50
    private let playerHeight: CGFloat = 90
    
    // Platform bounds
    private let platformBounds = (
        left: CGFloat(670),
        right: CGFloat(1170)
    )
    
    // Home position
    private let homePosition = CGPoint(x: 1250, y: 585) // Adjusted for platform2
    
    // Animation states
    @State private var walkFrame = 1
    @State private var lastAnimationTime = Date()
    private let animationInterval: TimeInterval = 0.08
    
    // Timer for physics
    let physicsTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    // Add computed properties to use LevelManager's persistent storage
    private var deathCount: Int {
        levelManager.getDeathCount(for: 2)
    }
    
    private var deathNotes: [(note: String, position: CGPoint, rotation: Double)] {
        levelManager.getDeathNotes(for: 2)
    }

    private var isControlsEnabled: Bool {
        return !isDead && !isLevelComplete
    }
    
    // NEW: Adjustable configuration for platform2
    private let platform2Config = (
        size: CGSize(width: 200, height: 50),   // Adjust size as needed
        position: CGPoint(x: 110, y: 650)        // Adjust position as needed
    )

    // NEW: Adjustable configuration for extra platform2.
    private let platform2Extra = (
        size: CGSize(width: 200, height: 50),   // Adjust size as needed
        position: CGPoint(x: 1200, y: 650)        // Adjust position as needed
    )

    // NEW: Configurable platforms for additional assets - remove delete and shift, keep return
    private let returnPlatform = (position: CGPoint(x: 655, y: 650), size: CGSize(width: 100, height: 50))

    // Add new roof configuration after existing platform configs:
    private let roofConfig = (
        size: CGSize(width: 200, height: 50),   // Adjust width/height as needed
        position: CGPoint(x: 455, y: 150)        // Adjust x/y position as needed
    )

    // Add second roof configuration after first roofConfig
    private let roofConfig2 = (
        size: CGSize(width: 200, height: 50),    // Adjust width/height as needed
        position: CGPoint(x: 900, y: 150)        // Adjust x/y position as needed
    )

    // Fix the roof boundary configuration - remove tuple syntax
    private let roofDeathHeight: CGFloat = 50   // Height at which player dies if they miss the roof

    // Add new state variables for gravity reversal
    @State private var isGravityReversed = false
    @State private var isRotating = false
    @State private var playerRotation = 0.0
    private let heightenedJumpForce: CGFloat = -20  // Stronger jump force for gravity reversal
    private let rotationDuration = 0.3  // Duration of flip animation

    @State private var predictionMessage: String? = nil  // NEW

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.white.ignoresSafeArea()
                
                // Death Notes Background Layer
                ForEach(deathNotes.indices, id: \.self) { index in
                    Image(deathNotes[index].note)
                        .resizable()
                        .frame(width: 150, height: 150)
                        .position(deathNotes[index].position)
                        .rotationEffect(.degrees(deathNotes[index].rotation))
                        .opacity(0.15)
                        .blur(radius: 0.5)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                        .overlay(
                            Color.white.opacity(0.1)
                                .blendMode(.overlay)
                        )
                        .zIndex(0.5)
                        .allowsHitTesting(false)
                }
                
                // NEW: Render remaining platform
                Image("return")
                    .resizable()
                    .frame(width: returnPlatform.size.width, height: returnPlatform.size.height)
                    .position(returnPlatform.position)
                
                // NEW: Re-add platform2 view
                Image("platform2")
                    .resizable()
                    .frame(width: platform2Config.size.width, height: platform2Config.size.height)
                    .position(platform2Config.position)
                
                // NEW: Render extra platform2.
                Image("platform2")
                    .resizable()
                    .frame(width: platform2Extra.size.width, height: platform2Extra.size.height)
                    .position(platform2Extra.position)
                
                // Add roof platform after existing platforms
                Image("Plat3-roof")
                    .resizable()
                    .frame(width: roofConfig.size.width, height: roofConfig.size.height)
                    .position(roofConfig.position)
                
                // Add second roof platform after first roof
                Image("Plat3-roof")
                    .resizable()
                    .frame(width: roofConfig2.size.width, height: roofConfig2.size.height)
                    .position(roofConfig2.position)
                
                // Home
                Image("Home")
                    .resizable()
                    .frame(width: 95, height: 80)
                    .position(homePosition)
                
                // Back button (add this)
                Button("Back to Map") {
                    levelManager.currentState = .progressMap
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .position(x: 100, y: 50)
                .zIndex(3)
                
                // NEW: Re-added Player view with its mechanics
                Player(currentState: playerState, facingRight: playerFacingRight, walkFrame: walkFrame)
                    .rotationEffect(.degrees(playerRotation))
                    .position(playerPosition)
                    .onReceive(physicsTimer) { _ in
                        updatePhysics(in: geometry)
                        updatePlayerState()
                        updateAnimation()
                    }
                
                // Controls
                Controls(
                    leftConfig: ControlConfig(
                        size: 100,
                        position: CGPoint(x: 100, y: geometry.size.height - 80),
                        opacity: isControlsEnabled ? 0.8 : 0.4
                    ),
                    jumpConfig: ControlConfig(
                        size: 100,
                        position: CGPoint(x: geometry.size.width - 100, y: geometry.size.height - 80),
                        opacity: isControlsEnabled ? 0.8 : 0.4
                    ),
                    rightConfig: ControlConfig(
                        size: 100,
                        position: CGPoint(x: 250, y: geometry.size.height - 80),
                        opacity: isControlsEnabled ? 0.8 : 0.4
                    ),
                    onLeftBegan: { 
                        if isControlsEnabled { 
                            isMovingLeft = true
                            playerState = .walking
                            // Don't set playerFacingRight here, let updatePlayerState handle it
                        }
                    },
                    onLeftEnded: { if isControlsEnabled { isMovingLeft = false; if !isMovingRight { playerState = .idle } } },
                    onRightBegan: { 
                        if isControlsEnabled {
                            isMovingRight = true
                            playerState = .walking
                            // Don't set playerFacingRight here, let updatePlayerState handle it
                        }
                    },
                    onRightEnded: { if isControlsEnabled { isMovingRight = false; if !isMovingLeft { playerState = .idle } } },
                    onJumpBegan: { 
                        if isControlsEnabled && isOnGround {
                            if !isGravityReversed {
                                // Normal jump with higher force
                                playerVelocity.y = heightenedJumpForce
                                isOnGround = false
                                playerState = .jumping
                                checkForJumpPeak()
                            } else {
                                // Reduced jump force when coming down from roof
                                playerVelocity.y = heightenedJumpForce * -0.7  // Reduced from -1 to -0.7
                                isOnGround = false
                                playerState = .jumping
                                
                                // Start rotation back to normal
                                withAnimation(.linear(duration: rotationDuration)) {
                                    playerRotation = 360
                                    isGravityReversed = false
                                }
                                // Reset rotation to 0 after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + rotationDuration) {
                                    playerRotation = 0
                                }
                            }
                        }
                    },
                    onJumpEnded: { }
                )
                
                // Death Counter
                Text("Deaths: \(deathCount)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.red)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.7))
                    )
                    .position(x: geometry.size.width / 2, y: 50)
                    .zIndex(3)

                // Level complete overlay
                if isLevelComplete {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .zIndex(4)
                    
                    Text("LEVEL COMPLETE!")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.green)
                        .padding()
                        .zIndex(4)
                }

                // Add death overlay with single increment
                if isDead {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .zIndex(4)
                    
                    Text("YOU DIED!")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.red)
                        .padding()
                        .zIndex(4)
                        .onAppear {
                            levelManager.incrementDeathCount(for: 2)  // Single increment here
                            addDeathNote(in: geometry)   // Add note only once here
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isDead = false
                            }
                        }
                }

                // Debug visualization of death height (comment out in production)
                if isLevelComplete {
                    Color.black.ignoresSafeArea()
                        .zIndex(4)
                        .onAppear {
                            // Run ML prediction (assumes getPredictionMessage() exists)
                            predictionMessage = getPredictionMessage()
                        }
                    VStack(spacing: 20) {
                        if let msg = predictionMessage {
                            Text(msg)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                        } else {
                            Text("Calculating ML Insights...")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.white)
                                .padding()
                        }
                        Button("Continue") {
                            withAnimation {
                                levelManager.currentState = .level(3)
                            }
                        }
                        .font(.system(size: 24, weight: .bold))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .zIndex(4)
                }
            }
        }
    }
    
    // Update physics function without platform2 collision logic:
    private func updatePhysics(in geometry: GeometryProxy) {
        // Apply gravity if not on ground
        if !isOnGround {
            // Apply gravity based on direction
            if isGravityReversed {
                playerVelocity.y -= gravity  // Reverse gravity
            } else {
                playerVelocity.y += gravity  // Normal gravity
            }
        }
        
        // Handle horizontal movement (removed player-related update)
        if isMovingLeft {
            playerPosition.x -= moveSpeed
        }
        if isMovingRight {
            playerPosition.x += moveSpeed
        }
        
        let newY = playerPosition.y + playerVelocity.y
        
        // UPDATED: Collision detection for platform2 now forces landing
        let platform2Top = platform2Config.position.y - platform2Config.size.height / 2
        let platform2Left = platform2Config.position.x - platform2Config.size.width / 2
        let platform2Right = platform2Config.position.x + platform2Config.size.width / 2
        if playerPosition.x >= platform2Left,
           playerPosition.x <= platform2Right,
           newY + 35 >= platform2Top {
            playerPosition.y = platform2Top - 35  // Snap player onto platform
            playerVelocity.y = 0
            isOnGround = true
        }
        // NEW: Collision detection for extra platform2.
        else if checkPlatformCollision(config: platform2Extra, newY: newY) {
            // Collision handled in checkPlatformCollision.
        }
        // NEW: Collision detection for extra platforms - only check return platform
        else if checkPlatformCollision(config: returnPlatform, newY: newY) {
            // Collision handled in checkPlatformCollision.
        }
        else {
            playerPosition.y = newY
            isOnGround = false
        }

        // Add roof collision check
        let roofBottom = roofConfig.position.y + roofConfig.size.height/2
        let roofLeft = roofConfig.position.x - roofConfig.size.width/2
        let roofRight = roofConfig.position.x + roofConfig.size.width/2
        
        // Check if player is within horizontal bounds of roof
        if playerPosition.x >= roofLeft && playerPosition.x <= roofRight {
            // Check if player is colliding with bottom of roof
            if newY - 35 <= roofBottom && playerPosition.y - 35 >= roofBottom {
                playerPosition.y = roofBottom + 35  // Place player on bottom of roof
                playerVelocity.y = 0
                isOnGround = true
            }
        }
        
        // Update roof collision to be solid from both directions
        let roofRect = CGRect(
            x: roofConfig.position.x - roofConfig.size.width/2,
            y: roofConfig.position.y - roofConfig.size.height/2,
            width: roofConfig.size.width,
            height: roofConfig.size.height
        )
        
        let playerRect = CGRect(
            x: playerPosition.x - 25,
            y: newY - 35,  // Use newY for prediction
            width: 50,
            height: 70
        )
        
        // Check for roof collision
        if playerRect.intersects(roofRect) {
            if playerVelocity.y < 0 {  // Moving upward
                // Hit bottom of roof
                playerPosition.y = roofRect.maxY + 35
                playerVelocity.y = 0
                isOnGround = true  // Set to true when hitting roof bottom
                playerState = .idle  // Trigger idle animation
            } else if playerVelocity.y > 0 {  // Moving downward
                // Land on top of roof
                playerPosition.y = roofRect.minY - 35
                playerVelocity.y = 0
                isOnGround = true
                playerState = .idle  // Trigger idle animation
            }
        }

        // Add collision check for second roof
        let roof2Rect = CGRect(
            x: roofConfig2.position.x - roofConfig2.size.width/2,
            y: roofConfig2.position.y - roofConfig2.size.height/2,
            width: roofConfig2.size.width,
            height: roofConfig2.size.height
        )
        
        if playerRect.intersects(roof2Rect) {
            if playerVelocity.y < 0 {  // Moving upward
                // Hit bottom of roof
                playerPosition.y = roof2Rect.maxY + 35
                playerVelocity.y = 0
                isOnGround = true
                playerState = .idle
            } else if playerVelocity.y > 0 {  // Moving downward
                // Land on top of roof
                playerPosition.y = roof2Rect.minY - 35
                playerVelocity.y = 0
                isOnGround = true
                playerState = .idle
            }
        }

        // Simplified roof boundary death check
        if playerPosition.y < roofDeathHeight && !isOnGround {  // Changed from > to <
            // Player has gone too high after missing the roof
            handleDeath(in: geometry)
        }

        // Check if fallen too far
        if playerPosition.y > geometry.size.height + 100 {
            handleDeath(in: geometry)
        }
        
        checkHomeCollision()
    }

    // NEW: Helper function for platform collision.
    private func checkPlatformCollision(config: (position: CGPoint, size: CGSize), newY: CGFloat) -> Bool {
        let platTop = config.position.y - config.size.height / 2
        let platLeft = config.position.x - config.size.width / 2
        let platRight = config.position.x + config.size.width / 2
        if playerPosition.x >= platLeft,
           playerPosition.x <= platRight,
           newY + 35 >= platTop {
            playerPosition.y = platTop - 35  // Snap player on top.
            playerVelocity.y = 0
            isOnGround = true
            return true
        }
        return false
    }
    
    private func checkHomeCollision() {
        let playerBounds = CGRect(
            x: playerPosition.x - 25,
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        
        let homeBounds = CGRect(
            x: homePosition.x - 47.5,
            y: homePosition.y - 40,
            width: 95,
            height: 80
        )
        
        if playerBounds.intersects(homeBounds) {
            isLevelComplete = true
            isMovingLeft = false
            isMovingRight = false
            playerVelocity = .zero
            playerState = .idle
            
            levelManager.unlockNextLevel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    levelManager.currentState = .level(3)
                }
            }
        }
    }
    
    private func resetPosition() {
        playerPosition = CGPoint(x: 130, y: 510)  // Reset to platform2
        playerVelocity = .zero
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
        playerFacingRight = true  // Reset facing direction
        isGravityReversed = false  // Ensure gravity is normal
        playerRotation = 0  // Ensure rotation is normal
    }
    
    // Remove death counter increment from handleDeath
    private func handleDeath(in geometry: GeometryProxy) {
        isDead = true
        isGravityReversed = false  // Reset gravity state
        playerRotation = 0  // Reset player rotation
        resetPosition()
    }

    // Update addDeathNote to accept geometry parameter
    private func addDeathNote(in geometry: GeometryProxy) {
        let notes = ["note1", "note2", "note3", "note4", "note5"]
        let noteIndex = deathCount % notes.count
        
        let randomX = CGFloat.random(in: 0...geometry.size.width)
        let randomY = CGFloat.random(in: 0...geometry.size.height)
        let rotation = Double.random(in: -30...30)
        
        levelManager.addDeathNote(
            for: 2,
            note: notes[noteIndex],
            position: CGPoint(x: randomX, y: randomY),
            rotation: rotation
        )
    }

    // Update updatePlayerState to handle roof animations correctly:
    private func updatePlayerState() {
        if !isOnGround {
            playerState = .jumping
        } else if isMovingLeft || isMovingRight {
            playerState = .walking
            if isGravityReversed {
                // When on roof, pressing right should make player face left and vice versa
                playerFacingRight = isMovingLeft
            } else {
                // Normal gravity - face the direction of movement
                playerFacingRight = isMovingRight
            }
        } else {
            playerState = .idle
            if isGravityReversed {
                playerFacingRight = false  // Face left when idle on roof
            }
        }
    }
    
    // Update updateAnimation to use normal walking sequence regardless of gravity:
    private func updateAnimation() {
        let now = Date()
        if playerState == .walking {
            if now.timeIntervalSince(lastAnimationTime) >= animationInterval {
                walkFrame = (walkFrame % 4) + 1  // Always use normal sequence: 1,2,3,4
                lastAnimationTime = now
            }
        } else if walkFrame != 1 {
            walkFrame = 1
            lastAnimationTime = now
        }
    }

    // Modify checkForJumpPeak to update facing direction:
    private func checkForJumpPeak() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if playerVelocity.y >= -0.5 && !isGravityReversed {  // Near peak of jump
                withAnimation(.linear(duration: rotationDuration)) {
                    playerRotation = 180
                    isGravityReversed = true
                    playerFacingRight = false  // Force left-facing when landing on roof
                }
                timer.invalidate()
            } else if isOnGround {
                timer.invalidate()
            }
        }
    }

    // Add new function to handle return animation:
    private func checkForReturnPeak() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if playerVelocity.y >= 0.5 && isGravityReversed {  // Check when player is moving down
                withAnimation(.linear(duration: rotationDuration)) {
                    playerRotation = 360  // Full rotation to return to normal
                    isGravityReversed = false
                }
                // After rotation completes, reset to 0 degrees
                DispatchQueue.main.asyncAfter(deadline: .now() + rotationDuration) {
                    playerRotation = 0
                }
                timer.invalidate()
            } else if isOnGround {
                timer.invalidate()
            }
        }
    }

    // NEW: Stub implementation for ML Insights prediction.
    private func getPredictionMessage() -> String {
        // Replace with a real ML call if needed.
        return "ML Insights:\nPlayer Type: Example\nFrustration: 50/100\nStats here..."
    }
}

#Preview {
    Level2()
        .environmentObject(LevelManager())
}

