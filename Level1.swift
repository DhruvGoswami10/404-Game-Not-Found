import SwiftUI
import Foundation
import CoreML

struct Level1: View {
    @EnvironmentObject private var levelManager: LevelManager
    @State private var playerState: PlayerState = .idle
    @State private var playerFacingRight = true
    
    // Add player state
    @State private var playerPosition = CGPoint(x: 120, y: 510) // y value adjusted to be on platform
    @State private var playerVelocity = CGPoint.zero
    @State private var isOnGround = true
    @State private var isMovingLeft = false
    @State private var isMovingRight = false
    @State private var idleStartTime = Date()
    
    // Existing states
    @State private var coffeeStates = [false, false, false, false, false, false, false]
    @State private var isDead = false
    
    // Add new state for touch counter
    @State private var touchCount = 0
    
    // Add cooldown state to prevent rapid touches
    @State private var canTouch = true
    
    // Add new state for level completion
    @State private var isLevelComplete = false
    
    // Add new state variables to track frustration metrics
    @State private var hesitationCount: Int = 0
    @State private var gameStartTime: Date = Date()
    @State private var lastMovementTime: Date = Date()
    private let hesitationThreshold: TimeInterval = 1.0  // Consider hesitation after 3 seconds of no movement
    
    // Add new state variables at the top of Level1 struct:
    @State private var levelStartTime = Date()
    @State private var currentLevelDeaths = 0
    @State private var totalTimeSpent: TimeInterval = 0

    @State private var internalErrors = 0
    @State private var timesFooled = 0

    // NEW: Hesitation zone configuration
    private let hesitationZones: [CGRect] = [
        CGRect(x: 380, y: 460, width: 130, height: 120),  // Before coffee3
        CGRect(x: 800, y: 460, width: 130, height: 120)   // Before coffee7
    ]
    @State private var isInHesitationZone = false
    @State private var hesitationStartTime: Date?

    // Physics constants - adjusted for better platform interaction
    private let gravity: CGFloat = 0.8
    private let jumpForce: CGFloat = -15
    private let platformY: CGFloat = 600 // Platform Y position
    private let platformHeight: CGFloat = 50
    private let playerHeight: CGFloat = 90 // Match player sprite height
    
    // Platform bounds adjusted for precise collision
    private let platformBounds = (
        left: CGFloat(50),  // Platform start x position
        right: CGFloat(1170), // Platform end x position
        y: CGFloat(600)     // Platform y position
    )
    
    // Timer for physics update
    let physicsTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    // Existing coffee config
    private let coffeeConfig: [(CGFloat, CGFloat, Bool)] = [
        (250, 550, false),     // coffee1
        (358.33, 550, false),  // coffee2
        (466.67, 550, true),   // coffee3 - deadly
        (575, 550, false),     // coffee4
        (683.33, 550, false),  // coffee5
        (791.67, 550, false),  // coffee6
        (900, 550, true)       // coffee7 - deadly
    ]
    
    // Add home position constant
    private let homePosition = CGPoint(x: 1050, y: 535)
    
    @State private var walkFrame = 1
    @State private var lastAnimationTime = Date()
    private let animationInterval: TimeInterval = 0.08  // Faster animation (was 0.1)
    private let moveSpeed: CGFloat = 7  // Faster movement (was 5)
    
    // Add computed property for controls state
    private var isControlsEnabled: Bool {
        return !isDead && !isLevelComplete
    }
    
    // Add computed properties to access LevelManager data
    private var deathCount: Int {
        levelManager.getDeathCount(for: 1)  // Use 2 for Level2
    }
    
    private var deathNotes: [(note: String, position: CGPoint, rotation: Double)] {
        levelManager.getDeathNotes(for: 1)  // Use 2 for Level2
    }
    
    @State private var debugLogs: [String] = []  // NEW: Debug log messages
    // NEW: Track if "Using Phone" has been logged
    @State private var hasLoggedUsingPhone: Bool = false
    // NEW: Track prediction message for player type classification
    @State private var predictionMessage: String? = nil

    // NEW: Helper function to add a debug log.
    private func debugLog(_ message: String) {
        debugLogs.append(message)
        // Optionally limit the log size, e.g.:
        if debugLogs.count > 11 { debugLogs.removeFirst() }
    }
    
    // NEW: Configurable terminal asset settings.
    private let terminalConfig = (position: CGPoint(x: 600, y: 300), size: CGSize(width: 900, height: 300))

    // NEW: Configurable debug overlay settings.
    private let debugOverlayConfig = (position: CGPoint(x: 565, y: 315), size: CGSize(width: 800, height: 230))

    // UPDATED: Instantiate the PlayerClassifier model as a constant.
    // Comment out auto-generated model reference if not available:
    // private let classifier: PlayerClassifier? = try? PlayerClassifier(configuration: MLModelConfiguration())

    // Similarly, if PlayerTypeClassifier and PlayerFrustration are unavailable,
    // ensure you either add their .mlmodel files to generate their classes
    // or update your code to load MLModel instances manually (as shown below).

    // Example of manual model instantiation:
    // Removed ML model instantiation because PlayerTypeClassifier and PlayerFrustration are not available.
    // Update model instantiation:
    private let typeClassifier: PlayerTypeClassifier? = try? PlayerTypeClassifier()
    private let frustrationModel: PlayerFrustration? = try? PlayerFrustration()

    // Add new state variables for transition effects
    @State private var fadeToBlack = false
    @State private var showTerminal = false
    @State private var terminalText = ""
    @State private var glitchEffect = false
    @State private var showWarning = false
    
    private let terminalLines = [
        "SYSTEM CHECK COMPLETE.\n",
        "Applying Physics Patch 1.0...\n",
        "- Gravity Inversion: Enabled\n",
        "- Player Adaptation: 0% (Good luck.)\n"
    ]

    // Add new state variables for transition
    @State private var showTransition = false
    @State private var transitionProgress: CGFloat = 0
    @State private var transitionText = "Loading Level 2..."
    @State private var showLoadingBar = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base Background (z-index: 0)
                Color.white.ignoresSafeArea()
                    .zIndex(0)
                
                // NEW: Add visible hesitation zones
                ForEach(hesitationZones.indices, id: \.self) { index in
                    Rectangle()
                        .fill(Color.red)
                        .opacity(0.7)  // Adjust opacity as needed
                        .frame(width: hesitationZones[index].width, 
                               height: hesitationZones[index].height)
                        .position(x: hesitationZones[index].midX, 
                                 y: hesitationZones[index].midY)
                        .zIndex(0.1)  // Between background and game elements
                }
                
                // NEW: Move debug overlay above the background.
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        ForEach(debugLogs, id: \.self) { log in
                            Text(log)
                                .font(.system(size: 16, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        // No Spacer needed to force scrolling effect.
                    }
                }
                .frame(width: debugOverlayConfig.size.width, height: debugOverlayConfig.size.height, alignment: .leading)
                .position(debugOverlayConfig.position)
                .allowsHitTesting(false)
                .zIndex(0.2)
                
                // NEW: Terminal background asset.
                Image("terminal")
                    .resizable()
                    .frame(width: terminalConfig.size.width, height: terminalConfig.size.height)
                    .position(terminalConfig.position)
                    .zIndex(0.1)
                
                // Death Notes Layer with further reduced opacity
                if !deathNotes.isEmpty {
                    ForEach(deathNotes.indices, id: \.self) { index in
                        if index < deathNotes.count {
                            Image(deathNotes[index].note)
                                .resizable()
                                .frame(width: 150, height: 150)
                                .position(deathNotes[index].position)
                                .rotationEffect(.degrees(deathNotes[index].rotation))
                                .opacity(0.7)  // Reduced opacity from 0.08 to 0.05
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2) // Reduced shadow opacity
                                .zIndex(0.1)
                                .allowsHitTesting(false)
                        }
                    }
                }
                
                // Game Content Layer (z-index: 1+)
                Group {
                    // Platform, Player, Coffees, etc
                    // ...existing game elements...
                    // Platform
                    Image("platform1")
                        .resizable()
                        .frame(width: 1000, height: 50)
                        .position(x: 590, y: platformY)
                    
                    // Player
                    Player(currentState: playerState, facingRight: playerFacingRight, walkFrame: walkFrame)
                        .position(playerPosition)
                        .onTapGesture {
                            guard !isDead && canTouch else { return }
                            
                            touchCount += 1
                            if touchCount == 1 {
                                debugLog("Bro why?")
                            } else if touchCount == 2 {
                                debugLog("Seriously mate?!")
                            }
                            canTouch = false  // Prevent rapid touches
                            
                            if touchCount >= 3 {
                                // Player dies after 3 touches
                                isDead = true
                                touchCount = 0  // Reset counter
                                resetPlayerPosition()
                            } else {
                                // Normal hey animation
                                playerState = .hey
                                // Return to previous state after 1 second
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    if !isMovingLeft && !isMovingRight && isOnGround {
                                        playerState = .idle
                                    } else if isOnGround {
                                        playerState = .walking
                                    } else {
                                        playerState = .jumping
                                    }
                                    // Allow next touch after animation completes
                                    canTouch = true
                                }
                            }
                        }
                        .onAppear {
                            debugLog("""
 _   _      _ _         ____  _                       
| | | | ___| | | ___   |  _ \\| | __ _ _   _  ___ _ __ 
| |_| |/ _ \\ | |/ _ \\  | |_) | |/ _` | | | |/ _ \\ '__|
|  _  |  __/ | | (_) | |  __/| | (_| | |_| |  __/ |   
|_| |_|\\___|_|_|\\___/  |_|   |_|\\__,_|\\__, |\\___|_|   
                                      |___/           
""")
                            debugLog("player spawned at (x=\(playerPosition.x), y=\(playerPosition.y))")
                        }
                        .onReceive(physicsTimer) { _ in
                            updatePhysics(in: geometry)  // Pass geometry here
                            updatePlayerState()
                            updateAnimation()
                        }
                    
                    // Coffees and other game elements
                    ForEach(0..<7) { index in
                        if (!coffeeStates[index]) {
                            Image("coffee")
                                .resizable()
                                .frame(width: 22, height: 35)
                                .position(x: coffeeConfig[index].0, y: coffeeConfig[index].1)
                                .onTapGesture {
                                    collectCoffee(index)
                                }
                        }
                    }
                    
                    // Home
                    Image("Home")
                        .resizable()
                        .frame(width: 95, height: 80)
                        .position(x: 1050, y: 535)
                }
                .zIndex(1)
                
                // UI Layer (z-index: 2+)
                Group {
                    // Back button
                    Button("Back to Map") {
                        levelManager.currentState = .progressMap
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .position(x: 100, y: 50)
                    
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
                        .zIndex(3)  // Keep above other elements
                    
                    // Add controls with custom configurations
                    Controls(
                        leftConfig: ControlConfig(
                            size: 100,  // Larger left button
                            position: CGPoint(x: 100, y: geometry.size.height - 80),
                            opacity: isControlsEnabled ? 0.8 : 0.4  // Dim when disabled
                        ),
                        jumpConfig: ControlConfig(
                            size: 100,  // Medium jump button
                            position: CGPoint(x: geometry.size.width - 100, y: geometry.size.height - 80),
                            opacity: isControlsEnabled ? 0.8 : 0.4
                        ),
                        rightConfig: ControlConfig(
                            size: 100,  // Larger right button
                            position: CGPoint(x: 250, y: geometry.size.height - 80),
                            opacity: isControlsEnabled ? 0.8 : 0.4
                        ),
                        onLeftBegan: {
                            guard isControlsEnabled else { return }
                            if (!isMovingLeft) {
                                debugLog("Player moved left")
                            }
                            isMovingLeft = true
                            playerState = .walking
                            playerFacingRight = false
                        },
                        onLeftEnded: {
                            guard isControlsEnabled else { return }
                            isMovingLeft = false
                            if (!isMovingRight) { playerState = .idle }
                        },
                        onRightBegan: {
                            guard isControlsEnabled else { return }
                            if (!isMovingRight) {
                                debugLog("Player moved right")
                            }
                            isMovingRight = true
                            playerState = .walking
                            playerFacingRight = true
                        },
                        onRightEnded: {
                            guard isControlsEnabled else { return }
                            isMovingRight = false
                            if (!isMovingLeft) { playerState = .idle }
                        },
                        onJumpBegan: {
                            guard isControlsEnabled else { return }
                            if (isOnGround) {
                                playerVelocity.y = jumpForce
                                isOnGround = false
                                playerState = .jumping
                                debugLog("Player jumped")
                            }
                        },
                        onJumpEnded: { }
                    )
                    
                    
                }
                .zIndex(3)
                
                // Death overlay
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
                            levelManager.incrementDeathCount(for: 1)
                            addDeathNote(in: geometry)  // Single call here
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isDead = false
                                coffeeStates = [false, false, false, false, false, false, false]
                            }
                        }
                }
                
                // NEW: Level Complete overlay showing prediction message.
                if isLevelComplete {
                    Color.black.opacity(fadeToBlack ? 1 : 1.0)
                        .ignoresSafeArea()
                        .zIndex(4)
                        .onAppear {
                            predictionMessage = MLInsights.getPredictionMessage(
                                level: 1,
                                totalDeaths: deathCount,
                                levelDeaths: currentLevelDeaths,
                                hesitationCount: hesitationCount,
                                timeSpent: totalTimeSpent,
                                internalErrors: nil,
                                timesFooled: nil,
                                playerTypeClassifier: typeClassifier,
                                frustrationModel: frustrationModel
                            )
                        }
                    if !showTerminal {
                        // Show initial completion message
                        VStack(spacing: 20) {
                            if let msg = predictionMessage {
                                Text(msg)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                            } else {
                                Text("Calculating your player style...")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            Button("Continue") {
                                startTransition()
                            }
                            .font(.system(size: 24, weight: .bold))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .zIndex(5)
                    } else {
                        // Show terminal animation
                        VStack(alignment: .leading, spacing: 5) {
                            Text(terminalText)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                                .multilineTextAlignment(.leading)
                                .padding()
                            
                            if showWarning {
                                Text("WARNING: User experience may suffer.")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.red)
                                    .opacity(glitchEffect ? 0.5 : 1)
                                    .animation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true), 
                                             value: glitchEffect)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .transition(.opacity)
                        .zIndex(5)
                    }
                }

                // Update level complete overlay in body
                if isLevelComplete {
                    // Dark overlay
                    Color.black
                        .opacity(showTransition ? 0.9 : 0)
                        .ignoresSafeArea()
                        .zIndex(10)
                    
                    VStack(spacing: 20) {
                        Text(transitionText)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(showTransition ? 1 : 0)
                        
                        if showLoadingBar {
                            // Loading bar
                            GeometryReader { metrics in
                                ZStack(alignment: .leading) {
                                    // Background bar
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 8)
                                    
                                    // Progress bar
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green)
                                        .frame(width: metrics.size.width * transitionProgress, height: 8)
                                }
                            }
                            .frame(width: 200)
                            .padding(.top, 10)
                        }
                    }
                    .zIndex(11)
                }
            }
            .onAppear {
                debugLog("Initializing level...")
            }
        }
    }
    
    private func updatePhysics(in geometry: GeometryProxy) {
        // Apply gravity if not on ground
        if !isOnGround {
            playerVelocity.y += gravity
        }
        
        // Handle horizontal movement without walls
        if isMovingLeft {
            playerPosition.x -= moveSpeed
            playerFacingRight = false
        }
        if isMovingRight {
            playerPosition.x += moveSpeed
            playerFacingRight = true
        }
        
        // Update vertical position
        let newY = playerPosition.y + playerVelocity.y
        
        // Platform collision detection
        let platformLeft = 100.0  // Left edge of platform
        let platformRight = 1170.0 // Right edge of platform
        let platformTopY = platformY - (platformHeight / 2) - (playerHeight / 2)
        
        // Only check for landing on platform if we're within its horizontal bounds
        if playerPosition.x >= platformLeft && playerPosition.x <= platformRight {
            if newY >= platformTopY && playerPosition.y < platformTopY {
                if playerVelocity.y > 0 { // Only if falling
                    playerPosition.y = platformTopY
                    playerVelocity.y = 0
                    isOnGround = true
                } else {
                    playerPosition.y = newY
                    isOnGround = false
                }
            } else {
                playerPosition.y = newY
                isOnGround = playerPosition.y >= platformTopY
            }
        } else {
            // If not above platform, continue falling
            playerPosition.y = newY
            isOnGround = false
        }
        
        // Check if player has fallen below platform level
        if playerPosition.y > platformY {
            isDead = true
            handleDeath(in: geometry)  // This will cause an error, we need to pass geometry
        }
        
        // Check coffee collisions
        checkCoffeeCollisions()
        
        // Add home collision check after movement updates
        checkHomeCollision()
    }
    
    private func checkCoffeeCollisions() {
        // Player collision bounds
        let playerBounds = CGRect(
            x: playerPosition.x - 25,  // Adjust these values based on player sprite
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        
        // Check each coffee
        for (index, coffee) in coffeeConfig.enumerated() {
            if !coffeeStates[index] {  // Only check uncollected coffee
                let coffeeBounds = CGRect(
                    x: coffee.0 - 11,  // Half of coffee width
                    y: coffee.1 - 17.5,  // Half of coffee height
                    width: 22,
                    height: 35
                )
                
                if playerBounds.intersects(coffeeBounds) {
                    // Collect or die based on coffee type
                    if coffee.2 {  // Deadly coffee
                        isDead = true
                        currentLevelDeaths += 1 // Increment level death counter
                        levelManager.incrementDeathCount(for: 1) // Increment total death count
                        debugLog("Coffee\(index + 1) killed player! Death count: \(currentLevelDeaths)")
                        resetPlayerPosition()
                    } else {
                        coffeeStates[index] = true
                        debugLog("Collecting coffee\(index + 1)")
                    }
                }
            }
        }
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
            
            // Calculate total time spent when level is completed
            totalTimeSpent = Date().timeIntervalSince(levelStartTime)
            
            // Unlock next level
            levelManager.unlockNextLevel()
            
            // Remove auto-transition code:
            // DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            //     withAnimation {
            //         levelManager.currentState = .level(2)  // Go directly to Level2
            //     }
            // }
            
            totalTimeSpent = Date().timeIntervalSince(levelStartTime)
            debugLog("""
                Level Complete Stats:
                - Deaths this attempt: \(currentLevelDeaths)
                - Total time: \(String(format: "%.1f", totalTimeSpent))s
                - Hesitations: \(hesitationCount)
                """)
        }
    }

    
    private func updatePlayerState() {
        if playerState == .hey || isDead {
            hasLoggedUsingPhone = false
            return
        }
        
        // Check if player is in any hesitation zone
        let playerBounds = CGRect(
            x: playerPosition.x - 25,
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        
        let wasInZone = isInHesitationZone
        isInHesitationZone = hesitationZones.contains { zone in
            zone.intersects(playerBounds)
        }
        
        // Start timer when entering zone
        if !wasInZone && isInHesitationZone {
            hesitationStartTime = Date()
        }
        
        // Check for hesitation only when in zone and not moving
        if isInHesitationZone && !isMovingLeft && !isMovingRight && isOnGround {
            if let startTime = hesitationStartTime {
                let currentTime = Date()
                let hesitationDuration = currentTime.timeIntervalSince(startTime)
                
                if hesitationDuration >= hesitationThreshold {
                    hesitationCount += 1
                    hesitationStartTime = currentTime  // Reset timer after counting hesitation
                }
            }
        } else if !isInHesitationZone {
            hesitationStartTime = nil  // Reset timer when moving or outside zone
        }
        
        // Update player visual state
        if !isOnGround {
            playerState = .jumping
            hasLoggedUsingPhone = false
        } else if isMovingLeft || isMovingRight {
            playerState = .walking
            hasLoggedUsingPhone = false
        } else {
            let idleTime = Date().timeIntervalSince(idleStartTime)
            if (idleTime > 3 && playerState != .hey) {
                if playerState != .usingPhone {
                    playerState = .usingPhone
                    if !hasLoggedUsingPhone {
                        debugLog("Using Phone")
                        hasLoggedUsingPhone = true
                    }
                }
            } else if playerState != .hey {
                playerState = .idle
                hasLoggedUsingPhone = false
            }
        }
    }

    
    private func updateAnimation() {
        if playerState == .walking {
            let now = Date()
            if now.timeIntervalSince(lastAnimationTime) >= animationInterval {
                walkFrame = (walkFrame % 4) + 1
                lastAnimationTime = now
            }
        }
    }
    
    private func collectCoffee(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if coffeeConfig[index].2 { // If coffee is deadly
                isDead = true
                // Reset player position when dead
                playerPosition = CGPoint(x: 120, y: 515)
                playerVelocity = .zero
                isOnGround = true
                debugLog("Coffee\(index + 1) is deadly, player died of common sense...")
            } else {
                coffeeStates[index] = true
                debugLog("Collecting coffee\(index + 1)")
            }
        }
    }
    
    private func resetPlayerPosition() {
        playerPosition = CGPoint(x: 120, y: 510)  // Reset to adjusted initial position
        playerVelocity = .zero
        isOnGround = true
        // Reset any movement states
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
        touchCount = 0
        canTouch = true
        resetMetrics()
    }
    
    // Remove death counter increment from handleDeath
    private func handleDeath(in geometry: GeometryProxy) {
        isDead = true
        currentLevelDeaths += 1  // Increment level-specific death counter
        debugLog("Death in current level: \(currentLevelDeaths)")  // Add debug logging
        resetPosition()
    }
    
    private func addDeathNote(in geometry: GeometryProxy) {
        let notes = ["note1", "note2", "note3", "note4", "note5"]
        let noteIndex = max(0, min(deathCount - 1, notes.count - 1)) % notes.count
        
        // Keep notes within visible area with some padding
        let padding: CGFloat = 100
        let randomX = CGFloat.random(in: padding...(geometry.size.width - padding))
        let randomY = CGFloat.random(in: padding...(geometry.size.height - padding))
        let rotation = Double.random(in: -30...30)
        
        levelManager.addDeathNote(
            for: 1,
            note: notes[noteIndex],
            position: CGPoint(x: randomX, y: randomY),
            rotation: rotation
        )
    }
    
    private func resetPosition() {
        playerPosition = CGPoint(x: 120, y: 510)
        playerVelocity = .zero
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
        resetMetrics()
    }

    // Update resetMetrics to only reset game-specific metrics:
    private func resetMetrics() {
        hesitationCount = 0
        gameStartTime = Date()
        lastMovementTime = Date()
        // Don't reset currentLevelDeaths here, as we want to track all deaths in current attempt
        levelStartTime = Date() // Reset level timer
    }

    // Add new transition handling functions
    private func startTransition() {
        // Remove the animation delay and start immediately
        showTerminal = true
        typeText()
    }
    
    private func typeText() {
        var currentText = ""
        for (index, line) in terminalLines.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                withAnimation {
                    currentText += line
                    terminalText = currentText
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                glitchEffect = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation {
                showWarning = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation {
                levelManager.currentState = .level(2)
            }
        }
    }

    private func handleLevelComplete() {
        isLevelComplete = true
        
        // Start transition sequence
        withAnimation(.easeInOut(duration: 0.5)) {
            showTransition = true
        }
        
        // Show loading bar after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                showLoadingBar = true
            }
            
            // Animate progress bar
            withAnimation(.easeInOut(duration: 2.0)) {
                transitionProgress = 1.0
            }
        }
        
        // Switch to Level 2 after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                levelManager.currentState = .level(2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        Level1()
            .environmentObject(LevelManager())
            .preferredColorScheme(.light)
    }
}
