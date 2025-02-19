import SwiftUI

struct Level2: View {
    @EnvironmentObject private var levelManager: LevelManager
    @State private var playerState: PlayerState = .idle
    @State private var playerFacingRight = true
    
    // Player state
    @State private var playerPosition = CGPoint(x: 110, y: 590) // Adjusted for platform2
    @State private var playerVelocity = CGPoint.zero
    @State private var isOnGround = true
    @State private var isMovingLeft = false
    @State private var isMovingRight = false
    @State private var isDead = false
    @State private var isLevelComplete = false
    @State private var hasDied = false
    
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
    private let homePosition = CGPoint(x: 1110, y: 585) // Adjusted for platform2
    
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
        position: CGPoint(x: 50, y: 650)        // Adjust position as needed
    )
    
    // NEW: Adjustable configuration for extra platform2.
    private let platform2Extra = (
        size: CGSize(width: 200, height: 50),   // Adjust size as needed
        position: CGPoint(x: 1120, y: 650)        // Adjust position as needed
    )
    
    // NEW: Configurable platforms for additional assets - remove delete and shift, keep return
    private let returnPlatform = (position: CGPoint(x: 590, y: 650), size: CGSize(width: 100, height: 50))
    
    // Update roof configurations - remove roofConfig3
    private let roofConfig = (
        size: CGSize(width: 300, height: 50),
        position: CGPoint(x: 380, y: 150)
    )
    
    private let roofConfig2 = (
        size: CGSize(width: 300, height: 50),
        position: CGPoint(x: 830, y: 150)
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
    
    // Add rotation state and configuration to spinner config
    private let spinnerConfig = (
        size: CGSize(width: 100, height: 80),     
        yPosition: CGFloat(450),                  
        leftBound: CGFloat(100),                 
        rightBound: CGFloat(1300),               
        speed: CGFloat(5.0),
        rotationSpeed: Double(360)  // Degrees per second
    )
    @State private var spinnerPosition: CGPoint
    @State private var spinnerMovingRight = true
    @State private var spinnerRotation = 0.0  // Add rotation state
    
    // Update spinner2Config to start from right side
    private let spinner2Config = (
        size: CGSize(width: 100, height: 80),     
        yPosition: CGFloat(350),                  // Different y position
        leftBound: CGFloat(100),                 // Different movement bounds
        rightBound: CGFloat(1300),               
        speed: CGFloat(7.0),                    // Different speed
        rotationSpeed: Double(540)              // Different rotation speed (1.5x faster)
    )
    @State private var spinner2Position: CGPoint
    @State private var spinner2MovingRight = false  // Start moving left
    @State private var spinner2Rotation = 0.0
    
    // Add ML-related state variables
    private let typeClassifier: PlayerTypeClassifier? = try? PlayerTypeClassifier()
    private let frustrationModel: PlayerFrustration? = try? PlayerFrustration()
    @State private var currentLevelDeaths: Int = 0
    @State private var hesitationCount: Int = 0
    @State private var totalTimeSpent: TimeInterval = 0
    @State private var levelStartTime = Date()
    
    // Add hesitation detection
    @State private var isInHesitationZone = false
    @State private var hesitationStartTime: Date?
    private let hesitationThreshold: TimeInterval = 1.0
    
    // Update hesitation zones with new zone and make them configurable
    private let hesitationZones: [HesitationZone] = [
        HesitationZone(bounds: CGRect(x: 400, y: 105, width: 130, height: 120)),  // Before first roof jump
        HesitationZone(bounds: CGRect(x: 850, y: 105, width: 130, height: 120)),  // Before second roof jump
        HesitationZone(bounds: CGRect(x: 515, y: 560, width: 150, height: 120))   // New zone above return platform
    ]

    // Add new struct to make zones more configurable
    struct HesitationZone {
        let bounds: CGRect
        var opacity: Double = 0.7
        var color: Color = .red
    }

    // Add new state variable for death cooldown
    @State private var canDie = true
    
    // Replace currentLevelDeaths with starting death count
    @State private var startingDeathCount: Int = 0

    // Remove timesFooled state variables
    @State private var hasBeenFooledBy: Set<String> = []

    // Add new state variables for installer transition
    @State private var showInstaller = false
    @State private var installerText = "INSTALLING LEVEL3.swift..."
    @State private var progressValue: Double = 0
    @State private var showError = false
    @State private var showGhostText = false
    @State private var isGlitching = false
    
    // Define installer sequence
    private let installerSequence = [
        (text: "INSTALLING LEVEL3.swift...\nEstimated Time: 10 seconds", progress: 0.25, delay: 1.5),
        (text: "Copying files...", progress: 0.45, delay: 1.0),
        (text: "Validating installation...", progress: 0.67, delay: 1.0),
        (text: "ERROR: Validation Failed.\nRetrying installation...", progress: 0.42, delay: 1.5),
        (text: "CRITICAL ERROR: File corrupted\nAttempting recovery...", progress: 0.15, delay: 1.0),
        (text: "Recovery failed...\nForcing installation...", progress: 0.89, delay: 1.0),
        (text: "", progress: 0.95, delay: 0.5),
        (text: "", progress: 0.0, delay: 0.5)
    ]

    // Update installer states
    @State private var showInstallerOverlay = false
    @State private var redFlashOpacity = 0.0
    @State private var flashCount = 0
    private let maxFlashes = 3
    private let flashDuration = 0.3
    private let flashInterval = 0.5

    // Add new state variables after existing ones
    @State private var idleStartTime = Date()
    @State private var canTouch = true
    @State private var hasLoggedUsingPhone = false
    @State private var touchCount = 0

    init() {
        // Initialize spinner position at left boundary
        _spinnerPosition = State(initialValue: CGPoint(
            x: spinnerConfig.leftBound,
            y: spinnerConfig.yPosition
        ))
        
        // Initialize second spinner at right boundary instead of left
        _spinner2Position = State(initialValue: CGPoint(
            x: spinner2Config.rightBound,
            y: spinner2Config.yPosition
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background
                Color.white.ignoresSafeArea()
                    .zIndex(0)
                
                // Death Notes Layer - keep behind all game elements
                if !deathNotes.isEmpty {
                    ForEach(deathNotes.indices, id: \.self) { index in
                        Image(deathNotes[index].note)
                            .resizable()
                            .frame(width: 150, height: 150)
                            .position(deathNotes[index].position)
                            .rotationEffect(.degrees(deathNotes[index].rotation))
                            .opacity(0.7)  // Keep very subtle
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2)
                            .zIndex(0.1)  // Just above background
                            .allowsHitTesting(false)
                    }
                }

                // Game elements with higher z-index values
                Group {
                    // Platforms
                    Image("return")
                        .resizable()
                        .frame(width: returnPlatform.size.width, height: returnPlatform.size.height)
                        .position(returnPlatform.position)
                        .zIndex(1)
                    
                    Image("platform2")
                        .resizable()
                        .frame(width: platform2Config.size.width, height: platform2Config.size.height)
                        .position(platform2Config.position)
                        .zIndex(1)
                    
                    Image("platform2")
                        .resizable()
                        .frame(width: platform2Extra.size.width, height: platform2Extra.size.height)
                        .position(platform2Extra.position)
                        .zIndex(1)
                    
                    Image("Plat3-roof")
                        .resizable()
                        .frame(width: roofConfig.size.width, height: roofConfig.size.height)
                        .position(roofConfig.position)
                        .zIndex(1)
                    
                    Image("Plat3-roof")
                        .resizable()
                        .frame(width: roofConfig2.size.width, height: roofConfig2.size.height)
                        .position(roofConfig2.position)
                        .zIndex(1)
                    
                    // Spinners
                    Image("spinner")
                        .resizable()
                        .frame(width: spinnerConfig.size.width, height: spinnerConfig.size.height)
                        .rotationEffect(.degrees(spinnerRotation))
                        .position(spinnerPosition)
                        .zIndex(2)
                    
                    Image("spinner")
                        .resizable()
                        .frame(width: spinner2Config.size.width, height: spinner2Config.size.height)
                        .rotationEffect(.degrees(spinner2Rotation))
                        .position(spinner2Position)
                        .zIndex(2)
                    
                    // Home and Player
                    Image("Home")
                        .resizable()
                        .frame(width: 95, height: 80)
                        .position(homePosition)
                        .zIndex(2)
                }

                // Player should be above all game elements
                Player(currentState: playerState, facingRight: playerFacingRight, walkFrame: walkFrame)
                    .rotationEffect(.degrees(playerRotation))
                    .position(playerPosition)
                    .zIndex(3)
                    .onTapGesture {
                        guard !isDead && !isLevelComplete && canTouch else { return }
                        
                        touchCount += 1
                        canTouch = false // Prevent rapid touches
                        
                        if touchCount >= 3 {
                            // Player dies after 3 touches
                            isDead = true
                            touchCount = 0 // Reset counter
                            handleDeath(in: geometry)
                        } else {
                            // Show hey animation
                            playerState = .hey
                            
                            // Return to previous state after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                if !isMovingLeft && !isMovingRight && isOnGround {
                                    playerState = .idle
                                } else if isOnGround {
                                    playerState = .walking
                                } else {
                                    playerState = .jumping
                                }
                                canTouch = true // Re-enable touch after animation
                            }
                        }
                    }
                    .onReceive(physicsTimer) { _ in
                        if !isLevelComplete {
                            updatePhysics(in: geometry)
                            updatePlayerState()
                            updateAnimation()
                            updateSpinner()  // Add spinner update
                            updateSpinner2()  // Add second spinner update
                        }
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
                    
                    if !showInstaller {
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
                                startInstallerSequence()
                            }
                            .font(.system(size: 24, weight: .bold))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .zIndex(5)
                    } else {
                        // Installer interface
                        VStack(spacing: 20) {
                            Text(installerText)
                                .font(.system(size: 24, weight: .regular, design: .monospaced))
                                .foregroundColor(.green)
                                .multilineTextAlignment(.leading)
                                .opacity(isGlitching ? 0.5 : 1)
                            
                            // Progress bar
                            GeometryReader { metrics in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                    
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: metrics.size.width * progressValue)
                                        .opacity(isGlitching ? 0.7 : 1)
                                }
                            }
                            .frame(height: 20)
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(15)
                        .padding()
                        .zIndex(5)
                    }
                    
                    // Ghost text overlay
                    if showGhostText {
                        Text("Installation incomplete. Proceeding anyway...")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                            .zIndex(6)
                    }
                }
                
                // Add Back to Map button
                Button("Back to Map") {
                    withAnimation {
                        levelManager.currentState = .progressMap
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .position(x: 100, y: 50)
                .zIndex(3)
                
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
                            // Run ML prediction using MLInsights
                            predictionMessage = MLInsights.getPredictionMessage(
                                level: 2,
                                totalDeaths: deathCount,
                                levelDeaths: levelManager.getTotalDeathCount() - startingDeathCount,
                                hesitationCount: hesitationCount,
                                timeSpent: totalTimeSpent,
                                internalErrors: nil,
                                timesFooled: nil,
                                playerTypeClassifier: typeClassifier,
                                frustrationModel: frustrationModel
                            )
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
                
                // Update hesitation zones visualization with new properties
                ForEach(hesitationZones.indices, id: \.self) { index in
                    Rectangle()
                        .fill(hesitationZones[index].color)
                        .opacity(hesitationZones[index].opacity)
                        .frame(width: hesitationZones[index].bounds.width, 
                               height: hesitationZones[index].bounds.height)
                        .position(x: hesitationZones[index].bounds.midX, 
                                 y: hesitationZones[index].bounds.midY)
                        .zIndex(0.1)
                }

                // New installer overlay
                if showInstaller {
                    // Dark grey background overlay
                    Color(red: 0.2, green: 0.2, blue: 0.2)
                        .ignoresSafeArea()
                        .opacity(0.95)
                        .zIndex(5)
                    
                    // Red flash overlay
                    Color.red
                        .ignoresSafeArea()
                        .opacity(redFlashOpacity)
                        .zIndex(6)
                    
                    // Installer content
                    VStack(spacing: 20) {
                        Text(installerText)
                            .font(.system(size: 24, weight: .regular, design: .monospaced))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.leading)
                            .opacity(isGlitching ? 0.5 : 1)
                        
                        // Progress bar
                        GeometryReader { metrics in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: metrics.size.width * progressValue)
                                    .opacity(isGlitching ? 0.7 : 1)
                            }
                        }
                        .frame(height: 20)
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.black)
                    .cornerRadius(15)
                    .padding()
                    .zIndex(7)
                    
                    // Ghost text overlay
                    if showGhostText {
                        Text("Installation incomplete. Proceeding anyway...")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                            .zIndex(8)
                    }
                }
            }
        }
        .onAppear {
            // Store initial death count to calculate new deaths in this level
            startingDeathCount = levelManager.getTotalDeathCount()
            levelStartTime = Date()
            currentLevelDeaths = 0  // Reset level-specific death counter
            debugLog("Level 2 started - Initial death count: \(startingDeathCount)")
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
        
        // Add roof2 collision check alongside roof1
        let roof2Bottom = roofConfig2.position.y + roofConfig2.size.height/2
        let roof2Left = roofConfig2.position.x - roofConfig2.size.width/2
        let roof2Right = roofConfig2.position.x + roofConfig2.size.width/2
        
        // Check if player is within horizontal bounds of either roof
        if (playerPosition.x >= roofLeft && playerPosition.x <= roofRight) ||
            (playerPosition.x >= roof2Left && playerPosition.x <= roof2Right) {
            // Check collision with first roof
            if playerPosition.x >= roofLeft && playerPosition.x <= roofRight &&
                newY - 35 <= roofBottom && playerPosition.y - 35 >= roofBottom {
                playerPosition.y = roofBottom + 35
                playerVelocity.y = 0
                isOnGround = true
            }
            // Check collision with second roof
            if playerPosition.x >= roof2Left && playerPosition.x <= roof2Right &&
                newY - 35 <= roof2Bottom && playerPosition.y - 35 >= roof2Bottom {
                playerPosition.y = roof2Bottom + 35
                playerVelocity.y = 0
                isOnGround = true
            }
        }
        
        // Update roof collision to be solid from both directions for both roofs
        let roofRect = CGRect(
            x: roofConfig.position.x - roofConfig.size.width/2,
            y: roofConfig.position.y - roofConfig.size.height/2,
            width: roofConfig.size.width,
            height: roofConfig.size.height
        )
        
        let roof2Rect = CGRect(
            x: roofConfig2.position.x - roofConfig2.size.width/2,
            y: roofConfig2.position.y - roofConfig2.size.height/2,
            width: roofConfig2.size.width,
            height: roofConfig2.size.height
        )
        
        let playerRect = CGRect(
            x: playerPosition.x - 25,
            y: newY - 35,
            width: 50,
            height: 70
        )
        
        // Check collisions with both roofs
        if playerRect.intersects(roofRect) {
            handleRoofCollision(roofRect)
        } else if playerRect.intersects(roof2Rect) {
            handleRoofCollision(roof2Rect)
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
        
        // Add spinner collision check
        let spinnerBounds = CGRect(
            x: spinnerPosition.x - spinnerConfig.size.width/2,
            y: spinnerPosition.y - spinnerConfig.size.height/2,
            width: spinnerConfig.size.width,
            height: spinnerConfig.size.height
        )
        
        let playerBounds = CGRect(
            x: playerPosition.x - 25,
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        
        if playerBounds.intersects(spinnerBounds) && canDie {
            canDie = false // Prevent multiple deaths
            handleDeath(in: geometry)
            print("Spinner death")
        }
        
        // Add second spinner collision check
        let spinner2Bounds = CGRect(
            x: spinner2Position.x - spinner2Config.size.width/2,
            y: spinner2Position.y - spinner2Config.size.height/2,
            width: spinner2Config.size.width,
            height: spinner2Config.size.height
        )
        
        if playerBounds.intersects(spinner2Bounds) && canDie {
            canDie = false // Prevent multiple deaths
            handleDeath(in: geometry)
            print("Spinner2 death")
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
            // First set completion state and stop physics
            isLevelComplete = true
            isMovingLeft = false
            isMovingRight = false
            playerVelocity = .zero
            playerState = .idle
            
            // Calculate total time spent when level completes (before unlocking next level)
            totalTimeSpent = Date().timeIntervalSince(levelStartTime)
            print("Level 2 completed in: \(String(format: "%.1f", totalTimeSpent))s")
            
            // Calculate deaths after time is recorded
            let currentDeaths = levelManager.getTotalDeathCount() - startingDeathCount
            
            // Generate ML insights with final stats using MLInsights directly
            predictionMessage = MLInsights.getPredictionMessage(
                level: 2,
                totalDeaths: deathCount,
                levelDeaths: currentDeaths,
                hesitationCount: hesitationCount,
                timeSpent: totalTimeSpent,
                internalErrors: nil,
                timesFooled: nil,  // Set to nil instead of passing timesFooled
                playerTypeClassifier: typeClassifier,
                frustrationModel: frustrationModel
            )
            
            // Unlock next level after stats are recorded
            levelManager.unlockNextLevel()
        }
    }
    
    private func resetPosition() {
        playerPosition = CGPoint(x: 110, y: 510)  // Reset to platform2
        playerVelocity = .zero
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
        playerFacingRight = true  // Reset facing direction
        isGravityReversed = false  // Ensure gravity is normal
        playerRotation = 0  // Ensure rotation is normal
        canDie = true // Re-enable death when player respawns
        idleStartTime = Date()
        hasLoggedUsingPhone = false
        canTouch = true
        touchCount = 0
    }
    
    private func handleDeath(in geometry: GeometryProxy) {
        isDead = true
        isGravityReversed = false  // Reset gravity state
        playerRotation = 0  // Reset player rotation
        resetPosition()
        
        // Log death for debugging
        print("Death in Level 2 - Total deaths: \(deathCount)")
    }
    
    // Update addDeathNote to accept geometry parameter
    private func addDeathNote(in geometry: GeometryProxy) {
        let notes = ["note1", "note2", "note3", "note4", "note5"]
        let noteIndex = deathCount % notes.count
        
        // Keep notes within visible area with padding
        let padding: CGFloat = 100
        let randomX = CGFloat.random(in: padding...(geometry.size.width - padding))
        let randomY = CGFloat.random(in: padding...(geometry.size.height - padding))
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
        // Add hesitation detection
        if isDead { return }
        
        let playerBounds = CGRect(
            x: playerPosition.x - 25,
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        
        let wasInZone = isInHesitationZone
        isInHesitationZone = hesitationZones.contains { zone in
            zone.bounds.intersects(playerBounds)
        }
        
        if !wasInZone && isInHesitationZone {
            hesitationStartTime = Date()
        }
        
        if isInHesitationZone && !isMovingLeft && !isMovingRight && isOnGround {
            if let startTime = hesitationStartTime {
                let currentTime = Date()
                let hesitationDuration = currentTime.timeIntervalSince(startTime)
                
                if hesitationDuration >= hesitationThreshold {
                    hesitationCount += 1
                    hesitationStartTime = currentTime
                }
            }
        } else if !isInHesitationZone {
            hesitationStartTime = nil
        }
        
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
            let idleTime = Date().timeIntervalSince(idleStartTime)
            if idleTime > 3 && playerState != .hey {
                if playerState != .usingPhone {
                    playerState = .usingPhone
                    if !hasLoggedUsingPhone {
                        print("Using Phone") // Optional debug log
                        hasLoggedUsingPhone = true
                    }
                }
            } else if playerState != .hey {
                playerState = .idle
                hasLoggedUsingPhone = false
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
    
    // Update updateSpinner to include rotation
    private func updateSpinner() {
        // Update position
        if spinnerMovingRight {
            spinnerPosition.x += spinnerConfig.speed
            if spinnerPosition.x >= spinnerConfig.rightBound {
                spinnerMovingRight = false
            }
        } else {
            spinnerPosition.x -= spinnerConfig.speed
            if spinnerPosition.x <= spinnerConfig.leftBound {
                spinnerMovingRight = true
            }
        }
        
        // Update rotation (60fps * 6 degrees = 360 degrees/second)
        spinnerRotation += spinnerConfig.rotationSpeed / 60
        if spinnerRotation >= 360 {
            spinnerRotation = 0 // Reset to prevent number getting too large
        }
    }
    
    // Update updateSpinner2 function to move in opposite direction
    private func updateSpinner2() {
        // Update position from right to left
        if spinner2MovingRight {
            spinner2Position.x += spinner2Config.speed
            if spinner2Position.x >= spinner2Config.rightBound {
                spinner2MovingRight = false
            }
        } else {
            spinner2Position.x -= spinner2Config.speed
            if spinner2Position.x <= spinner2Config.leftBound {
                spinner2MovingRight = true
            }
        }
        
        // Rotate counter-clockwise (negative rotation speed)
        spinner2Rotation -= spinner2Config.rotationSpeed / 60
        if spinner2Rotation <= -360 {
            spinner2Rotation = 0
        }
    }
    
    // Add helper function for roof collision handling
    private func handleRoofCollision(_ roofRect: CGRect) {
        if playerVelocity.y < 0 {  // Moving upward
            // Hit bottom of roof
            playerPosition.y = roofRect.maxY + 35
            playerVelocity.y = 0
            isOnGround = true
            playerState = .idle
        } else if playerVelocity.y > 0 {  // Moving downward
            // Land on top of roof
            playerPosition.y = roofRect.minY - 35
            playerVelocity.y = 0
            isOnGround = true
            playerState = .idle
        }
    }

    // Add new transition handling functions
    private func startInstallerSequence() {
        showInstaller = true
        showInstallerOverlay = true
        
        var totalDelay: Double = 0
        
        // Run through installer sequence with glitch effects
        for (index, sequence) in installerSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    installerText = sequence.text
                    progressValue = sequence.progress
                    
                    // Add glitch effects after error messages
                    if index >= 3 {
                        isGlitching = true
                        // Add screen shake effect
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    }
                }
            }
            totalDelay += sequence.delay
        }
        
        // Show ghost text and start red flashing
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            withAnimation(.easeIn(duration: 0.5)) {
                showGhostText = true
                isGlitching = true
            }
            startRedFlashing()
        }
    }
    
    // Add new function for red flashing effect
    private func startRedFlashing() {
        guard flashCount < maxFlashes else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showGhostText = false
                    redFlashOpacity = 0
                    
                    // Add final screen shake
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    
                    // Transition to next level
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            levelManager.currentState = .level(3)
                        }
                    }
                }
            }
            return
        }
        
        // Intensify flash effect with each iteration
        let flashIntensity = Double(flashCount + 1) * 0.2
        
        withAnimation(.easeIn(duration: flashDuration)) {
            redFlashOpacity = flashIntensity
            
            // Add haptic feedback for each flash
            let impact = UIImpactFeedbackGenerator(style: .rigid)
            impact.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + flashDuration) {
            withAnimation(.easeOut(duration: flashDuration)) {
                redFlashOpacity = 0
            }
            
            flashCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + flashInterval) {
                startRedFlashing()
            }
        }
    }
}

#Preview {
    Level2()
        .environmentObject(LevelManager())
}

