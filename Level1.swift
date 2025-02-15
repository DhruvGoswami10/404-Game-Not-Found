import SwiftUI
import Foundation
import CoreML

// Add model wrapper types:
struct PlayerTypeClassifier {
    let model: MLModel
    
    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "PlayerTypeClassifier", withExtension: "mlmodelc") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
        }
        self.model = try MLModel(contentsOf: modelURL)
    }
    
    func prediction() throws -> String {
        // Make prediction using model
        let input = try MLDictionaryFeatureProvider(dictionary: [:])
        let output = try model.prediction(from: input)
        return output.featureValue(for: "label")?.stringValue ?? "Unknown"
    }
}

struct PlayerFrustration {
    let model: MLModel
    
    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "PlayerFrustration", withExtension: "mlmodelc") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
        }
        self.model = try MLModel(contentsOf: modelURL)
    }
    
    func prediction() throws -> Double {
        // Make prediction using model
        let input = try MLDictionaryFeatureProvider(dictionary: [:])
        let output = try model.prediction(from: input)
        return output.featureValue(for: "frustrationScore")?.doubleValue ?? 0.0
    }
}

struct Level1: View {
    @EnvironmentObject private var levelManager: LevelManager
    @State private var playerState: PlayerState = .idle
    @State private var playerFacingRight = true
    
    // Add player state
    @State private var playerPosition = CGPoint(x: 200, y: 510) // y value adjusted to be on platform
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
    private let hesitationThreshold: TimeInterval = 3.0  // Consider hesitation after 3 seconds of no movement
    
    // Add new state variables at the top of Level1 struct:
    @State private var levelStartTime = Date()
    @State private var currentLevelDeaths = 0
    @State private var totalTimeSpent: TimeInterval = 0

    @State private var internalErrors = 0
    @State private var timesFooled = 0

    // Physics constants - adjusted for better platform interaction
    private let gravity: CGFloat = 0.8
    private let jumpForce: CGFloat = -15
    private let platformY: CGFloat = 600 // Platform Y position
    private let platformHeight: CGFloat = 50
    private let playerHeight: CGFloat = 90 // Match player sprite height
    
    // Platform bounds adjusted for precise collision
    private let platformBounds = (
        left: CGFloat(170),  // Platform start x position
        right: CGFloat(1170), // Platform end x position
        y: CGFloat(600)     // Platform y position
    )
    
    // Timer for physics update
    let physicsTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    // Existing coffee config
    private let coffeeConfig: [(CGFloat, CGFloat, Bool)] = [
        (350, 550, false),  // coffee1
        (455, 550, false),  // coffee2
        (560, 550, false),   // coffee3 - deadly
        (665, 550, false),  // coffee4
        (770, 550, false),  // coffee5
        (875, 550, false),  // coffee6
        (980, 550, false)   // coffee7 - deadly
    ]
    
    // Add home position constant
    private let homePosition = CGPoint(x: 1100, y: 535)
    
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
    private let terminalConfig = (position: CGPoint(x: 670, y: 300), size: CGSize(width: 900, height: 300))

    // NEW: Configurable debug overlay settings.
    private let debugOverlayConfig = (position: CGPoint(x: 630, y: 315), size: CGSize(width: 800, height: 230))

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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base Background (z-index: 0)
                Color.white.ignoresSafeArea()
                    .zIndex(0)
                
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
                
                // Death Notes Background Layer (z-index: 0.5)
                if !deathNotes.isEmpty {
                    ForEach(deathNotes.indices, id: \.self) { index in
                        if index < deathNotes.count {  // Add bounds check
                            Image(deathNotes[index].note)
                                .resizable()
                                .frame(width: 150, height: 150)
                                .position(deathNotes[index].position)
                                .rotationEffect(.degrees(deathNotes[index].rotation))
                                .opacity(0.15)  // More transparent
                                .blur(radius: 0.5)  // Slight blur effect
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                                .overlay(
                                    Color.white.opacity(0.1)  // Subtle white overlay
                                        .blendMode(.overlay)
                                )
                                .zIndex(0.5)
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
                        .position(x: 670, y: platformY)
                    
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
                        if !coffeeStates[index] {
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
                        .position(x: 1100, y: 535)
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
                    Color.black.ignoresSafeArea()
                        .zIndex(4)
                        .onAppear {
                            // Run ML prediction when level is complete.
                            predictionMessage = getPredictionMessage()
                            // 3. Example call in your level-complete overlay or relevant spot:
                            let insights = getPlayerInsights()
                            let playerType = insights.playerType
                            let frustrationScore = insights.frustrationScore
                            // Use playerType & frustrationScore however needed...
                        }
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
                            withAnimation {
                                levelManager.currentState = .level(2)
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
        let platformLeft = 170.0  // Left edge of platform
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
                        resetPlayerPosition()
                        debugLog("Coffee\(index + 1) is deadly, player died of common sense...")
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
        // Don't update state if player is in hey animation or is dead
        if playerState == .hey || isDead {
            hasLoggedUsingPhone = false
            return
        }
        
        // Update state based on movement and ground contact
        if !isOnGround {
            playerState = .jumping
            hasLoggedUsingPhone = false
        } else if isMovingLeft || isMovingRight {
            playerState = .walking
            idleStartTime = Date()
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
        
        if !isMovingLeft && !isMovingRight && isOnGround {
            let currentTime = Date()
            let timeSinceLastMovement = currentTime.timeIntervalSince(lastMovementTime)
            
            if timeSinceLastMovement >= hesitationThreshold {
                hesitationCount += 1
                lastMovementTime = currentTime  // Reset timer after counting hesitation
            }
        } else {
            lastMovementTime = Date()  // Update last movement time
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
                playerPosition = CGPoint(x: 400, y: 515)
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
        playerPosition = CGPoint(x: 200, y: 510)  // Reset to adjusted initial position
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
        
        let randomX = CGFloat.random(in: 0...geometry.size.width)
        let randomY = CGFloat.random(in: 0...geometry.size.height)
        let rotation = Double.random(in: -30...30)
        
        levelManager.addDeathNote(
            for: 1,  // Use 2 for Level2
            note: notes[noteIndex],
            position: CGPoint(x: randomX, y: randomY),
            rotation: rotation
        )
    }
    
    private func resetPosition() {
        playerPosition = CGPoint(x: 200, y: 510)
        playerVelocity = .zero
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
        resetMetrics()
    }

    // NEW: Updated getPredictionMessage() to fix compilation errors.
    private func getPredictionMessage() -> String {
        // Use the pre-instantiated classifier.
        let playerType: String = {
            if let tc = typeClassifier, let prediction = try? tc.prediction() {
                return prediction
            }
            return "Unknown"
        }()
        
        // Just use the raw player type directly
        let mappedPlayerType: String = {
            switch playerType {
            case "Speedrunner":
            return "Speedrunner"
            case "Explorer": 
            return "Explorer"
            case "Hesitant":
            return "Hesitant"
            case "Risk-Taker":
            return "Risk-Taker" 
            case "Strategist":
            return "Strategist"
            default:
            return "Speedrunner"
            }
        }()
        
        let frustrationScore: Double = {
            let baseScore = min(deathCount * 10, 100)
            return Double(baseScore)
        }()
        
        let frustrationMessage: String = {
            switch Int(frustrationScore) {
            case 0...20:
                let messages = [
                    "Smooth sailing! You breezed through this level with minimal frustration.",
                    "Zen mode activated: nothing rattled you this time."
                ]
                return messages.randomElement()!
            case 31...50:
                let messages = [
                    "You’re starting to feel the heat—try a more deliberate approach next time.",
                    "A little tension in your gameplay; a calm, measured move might work wonders."
                ]
                return messages.randomElement()!
            case 51...70:
                let messages = [
                    "Things are getting intense—perhaps take a brief pause to regroup.",
                    "Your frustration is showing; consider slowing down and rethinking your strategy."
                ]
                return messages.randomElement()!
            case 71...100:
                let messages = [
                    "Complete meltdown! It might be time for a break before you try again.",
                    "Critical stress detected! Step back, relax, and come back refreshed."
                ]
                return messages.randomElement()!
            default:
                return "Keep playing and improve your game!"
            }
        }()
        
        let insights = getPlayerInsights()
        let formattedTime = String(format: "%.1f", totalTimeSpent)
        
        return """
        ML Insights:
        - Player Type: \(mappedPlayerType)
        - Frustration: \(String(format: "%.2f", insights.frustrationScore))/100
        
        Stats:
        - Total Deaths: \(deathCount)
        - Level Deaths: \(currentLevelDeaths)
        - Hesitations: \(hesitationCount)
        - Time: \(formattedTime)s

        \(frustrationMessage)
        """
    }

    // 2. Add a helper to predict player type & frustration:
    private func getPlayerInsights() -> (playerType: String, frustrationScore: Double) {
        var predictedType = "Unknown"
        var frustrationScore = 0.0
        
        // Example usage:
        if let tc = typeClassifier,
           let tResult = try? tc.prediction() { // Replace with real input(s) as needed
            predictedType = tResult
        }
        
        // Calculate frustration components
        let timeSpent = Date().timeIntervalSince(gameStartTime)
        
        // Weights for the formula
        let w1: Double = 0.35
        let w2: Double = 0.20
        let w3: Double = 0.15
        let w4: Double = 0.20
        let w5: Double = 0.10

        // Maximum values for normalization
        let maxDeaths: Double = 50
        let maxHesitation: Double = 10
        let maxTime: Double = 30
        let maxErrors: Double = 8
        let maxFooled: Double = 7

        // Calculate normalized frustration score
        frustrationScore = (
            (w1 * Double(deathCount) / maxDeaths) +
            (w2 * Double(hesitationCount) / maxHesitation) +
            (w3 * timeSpent / maxTime) +
            (w4 * Double(internalErrors) / maxErrors) +
            (w5 * Double(timesFooled) / maxFooled)
        ) * 100.0
        
        // Clamp the score between 0 and 100
        frustrationScore = max(0, min(frustrationScore, 100))
        
        return (predictedType, frustrationScore)
    }
    
    // Update resetMetrics to only reset game-specific metrics:
    private func resetMetrics() {
        hesitationCount = 0
        gameStartTime = Date()
        lastMovementTime = Date()
        // Don't reset currentLevelDeaths here, as we want to track all deaths in current attempt
        levelStartTime = Date() // Reset level timer
    }

    // Add new helper function to classify player type:
    private func classifyPlayerType(
        deaths: Int,
        hesitation: Int,
        timeSpent: TimeInterval,
        internalErrors: Int,
        timesFooled: Int
    ) -> String {
        let timeInMinutes = timeSpent / 60.0
        if deaths <= 15 && hesitation <= 2 && timeInMinutes <= 10 && internalErrors <= 3 && timesFooled <= 2 {
            return "Speedrunner"
        } else if deaths <= 10 && hesitation >= 3 && timeInMinutes >= 15 && internalErrors >= 1 && timesFooled >= 1 {
            return "Explorer"
        } else if deaths >= 5 && hesitation >= 5 && timeInMinutes >= 20 && internalErrors >= 2 && timesFooled >= 2 {
            return "Hesitant"
        } else if deaths >= 20 && hesitation <= 3 && timeInMinutes <= 15 && internalErrors >= 3 && timesFooled <= 4 {
            return "Risk-Taker"
        } else {
            return "Strategist"
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


