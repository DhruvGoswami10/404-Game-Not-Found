import SwiftUI

// Helper function for debug logging
func debugLog(_ message: String) {
    #if DEBUG
    print("Debug: \(message)")
    #endif
}

struct Level4: View {
    @EnvironmentObject private var levelManager: LevelManager  // NEW: Added environment object for levelManager

    // NEW: Computed death counter and deathNotes for level 4
    private var deathCount: Int {
        levelManager.getDeathCount(for: 4)
    }
    private var deathNotes: [(note: String, position: CGPoint, rotation: Double)] {
        levelManager.getDeathNotes(for: 4)
    }

    // NEW: Adjustable settings for 'platform4'
    private let platform4Size: CGSize = CGSize(width: 1200, height: 50)    // Adjust as needed.
    private let platform4Position: CGPoint = CGPoint(x: 650, y: 550)        // Adjust as needed.
    
    // NEW: Adjustable settings for three 'coffee' assets
    private let coffee1Size: CGSize = CGSize(width: 22, height: 35)  // Adjust as needed.
    private let coffee1Position: CGPoint = CGPoint(x: 850, y: 500)     // Adjust as needed.
    private let coffee2Size: CGSize = CGSize(width: 22, height: 35)   // Adjust as needed.
    private let coffee2Position: CGPoint = CGPoint(x: 950, y: 500)     // Adjust as needed.
    private let coffee3Size: CGSize = CGSize(width: 22, height: 35)      // Adjust as needed.
    private let coffee3Position: CGPoint = CGPoint(x: 1050, y: 500)     // Adjust as needed.
    
    // NEW: Player state variables and physics constants
    @State private var playerState: PlayerState = .idle
    @State private var playerFacingRight = false  // Changed from true to false for left-facing start
    @State private var playerPosition = CGPoint(x: 1200, y: 300)           // Adjust starting position
    @State private var playerVelocity = CGPoint.zero
    @State private var isOnGround = true
    @State private var isMovingLeft = false
    @State private var isMovingRight = false
    
    // NEW: Running animation state
    @State private var walkFrame = 1
    @State private var lastAnimationTime = Date()
    private let animationInterval: TimeInterval = 0.08
    
    private let gravity: CGFloat = 0.8
    private let jumpForce: CGFloat = -15
    private let moveSpeed: CGFloat = 7
    let physicsTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    // NEW: New state to toggle swapped controls and show message
    @State private var swappedControls = false
    @State private var showSwappedMessage = false

    // NEW: Rejected asset configuration constants
    private let rejected1Size: CGSize = CGSize(width: 210, height: 100)       // Adjust size
    private let rejected1Start: CGPoint = CGPoint(x: 300, y: 400)            // Adjust starting position
    private let rejected1Speed: CGFloat = 9.0                                // Adjust speed
    private let rejected1MaxTop: CGFloat = 200                               // Adjust max top (minimum y)
    private let rejected1MaxBottom: CGFloat = 650                            // Adjust max bottom (maximum y)
    private let rejected1Rotation: Angle = .degrees(90)                      // Adjust rotation

    private let rejected2Size: CGSize = CGSize(width: 210, height: 100)
    private let rejected2Start: CGPoint = CGPoint(x: 500, y: 400)
    private let rejected2Speed: CGFloat = 7.0
    private let rejected2MaxTop: CGFloat = 200
    private let rejected2MaxBottom: CGFloat = 650
    private let rejected2Rotation: Angle = .degrees(90)

    private let rejected3Size: CGSize = CGSize(width: 210, height: 100)
    private let rejected3Start: CGPoint = CGPoint(x: 700, y: 400)
    private let rejected3Speed: CGFloat = 5.0
    private let rejected3MaxTop: CGFloat = 200
    private let rejected3MaxBottom: CGFloat = 650
    private let rejected3Rotation: Angle = .degrees(90)

    // NEW: Rejected asset state variables
    @State private var rejected1Position: CGPoint
    @State private var rejected1MovingUp: Bool = true

    @State private var rejected2Position: CGPoint
    @State private var rejected2MovingUp: Bool = true

    @State private var rejected3Position: CGPoint
    @State private var rejected3MovingUp: Bool = true
    
    // NEW: Home asset adjustment constants
    private let homeSize: CGSize = CGSize(width: 80, height: 80)   // Adjust as needed.
    private let homePosition: CGPoint = CGPoint(x: 120, y: 480)       // Adjust as needed.
    
    // NEW: Bin asset size adjustment constant
    private let binSize: CGSize = CGSize(width: 80, height: 100)    // Adjust as needed.
    
    // NEW: State variables for bin animation
    @State private var homeVisible: Bool = true
    @State private var showBin: Bool = false
    @State private var binPosition: CGPoint
    
    // NEW: Add death and completion states
    @State private var isDead = false
    @State private var isLevelComplete = false

    // NEW: Add dark mode states
    @State private var isDarkMode = false
    @State private var showTorch = false
    @State private var torchPosition: CGPoint = .zero

    // NEW: Add glowing text state
    @State private var showGlowingText = false
    private let glowingText = "/Users/You/Documents/WhyAreYouStillPlaying/Home.app"

    // NEW: Add glowing text position constants
    private let glowingTextPosition = CGPoint(x: 650, y: 340)  // Adjust these values as needed

    // NEW: Add BSOD state
    @State private var showBSOD = false
    
    // NEW: Add text collision bounds
    private let glowingTextSize = CGSize(width: 400, height: 40)  // Adjust based on text size

    // NEW: Add states for X button and message
    @State private var showXButton = false
    @State private var showMessage = false

    // Add ML-related state variables after existing state variables
    private let typeClassifier: PlayerTypeClassifier? = try? PlayerTypeClassifier()
    private let frustrationModel: PlayerFrustration? = try? PlayerFrustration()
    @State private var predictionMessage: String? = nil
    @State private var currentLevelDeaths: Int = 0
    @State private var hesitationCount: Int = 0
    @State private var totalTimeSpent: TimeInterval = 0
    @State private var levelStartTime = Date()

    // Add new state for troll message
    @State private var showTrollMessage = false

    // Add new state variable for timesFooled
    @State private var timesFooled: Int = 0

    // Add state to track which obstacles have already fooled the player
    @State private var hasBeenFooledBy: Set<String> = []

    // Add hesitation zone configuration
    private let hesitationZones: [CGRect] = [
        CGRect(x: 1000, y: 405, width: 130, height: 120),  // Before dark mode area
        CGRect(x: 750, y: 405, width: 100, height: 120),   // Before moving obstacles
        CGRect(x: 550, y: 405, width: 100, height: 120),
        CGRect(x: 350, y: 405, width: 100, height: 120)
    ]
    @State private var isInHesitationZone = false
    @State private var hesitationStartTime: Date?
    private let hesitationThreshold: TimeInterval = 1.0

    init() {
        _rejected1Position = State(initialValue: rejected1Start)
        _rejected2Position = State(initialValue: rejected2Start)
        _rejected3Position = State(initialValue: rejected3Start)
        // Initialize binPosition at the bottom of platform4.
        let platform4Bottom = platform4Position.y + platform4Size.height/2  // e.g. 575
        _binPosition = State(initialValue: CGPoint(x: homePosition.x, y: platform4Bottom))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                // NEW: Death Notes Background Layer
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
                
                // NEW: Death Counter overlay
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
                
                // ...existing background/platform code...
                Image("platform4")
                    .resizable()
                    .frame(width: platform4Size.width, height: platform4Size.height)
                    .position(platform4Position)
                
                // Add hesitation zones visualization after background
                ForEach(hesitationZones.indices, id: \.self) { index in
                    Rectangle()
                        .fill(Color.red)
                        .opacity(0.7)
                        .frame(width: hesitationZones[index].width, 
                               height: hesitationZones[index].height)
                        .position(x: hesitationZones[index].midX, 
                                 y: hesitationZones[index].midY)
                        .zIndex(0.1)
                }

                // NEW: Conditionally show game elements based on dark mode
                if !isDarkMode {
                    // Show regular game elements
                    Group {
                        // Coffee assets
                        Image("coffee")
                            .resizable()
                            .frame(width: coffee1Size.width, height: coffee1Size.height)
                            .position(coffee1Position)
                        Image("coffee")
                            .resizable()
                            .frame(width: coffee2Size.width, height: coffee2Size.height)
                            .position(coffee2Position)
                        Image("coffee")
                            .resizable()
                            .frame(width: coffee3Size.width, height: coffee3Size.height)
                            .position(coffee3Position)
                        
                        // Rejected assets
                        Image("rejected")
                            .resizable()
                            .frame(width: rejected1Size.width, height: rejected1Size.height)
                            .rotationEffect(rejected1Rotation)
                            .position(rejected1Position)
                        Image("rejected")
                            .resizable()
                            .frame(width: rejected2Size.width, height: rejected2Size.height)
                            .rotationEffect(rejected2Rotation)
                            .position(rejected2Position)
                        Image("rejected")
                            .resizable()
                            .frame(width: rejected3Size.width, height: rejected3Size.height)
                            .rotationEffect(rejected3Rotation)
                            .position(rejected3Position)
                    }
                }
                
                // NEW: Conditionally show Home asset.
                if homeVisible {
                    Image("Home")
                        .resizable()
                        .frame(width: homeSize.width, height: homeSize.height)
                        .position(homePosition)
                }
                
                // NEW: Display and animate Bin from assets when triggered.
                if showBin {
                    Image("bin")
                        .resizable()
                        .frame(width: binSize.width, height: binSize.height)
                        .position(binPosition)
                }
                
                // UPDATED: Pass walkFrame to Player view
                Player(currentState: playerState, facingRight: playerFacingRight, walkFrame: walkFrame)
                    .position(playerPosition)
                    .onReceive(physicsTimer) { _ in
                        updatePhysics(in: geometry)
                        updatePlayerState()
                        updateAnimation()
                        updateRejected()  // NEW: update rejected assets movement
                        if isDarkMode {
                            torchPosition = playerPosition // Update torch position to follow player
                        }
                    }
                
                // Display swapped message overlay when active.
                if showSwappedMessage {
                    Text("Left is the new right")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        .zIndex(4)
                }
                
                // NEW: Simple controls (adjust as needed)
                Controls(
                    leftConfig: ControlConfig(
                        size: 100,
                        position: CGPoint(x: 100, y: geometry.size.height - 80),
                        opacity: 0.8
                    ),
                    jumpConfig: ControlConfig(
                        size: 100,
                        position: CGPoint(x: geometry.size.width - 100, y: geometry.size.height - 80),
                        opacity: 0.8
                    ),
                    rightConfig: ControlConfig(
                        size: 100,
                        position: CGPoint(x: 250, y: geometry.size.height - 80),
                        opacity: 0.8
                    ),
                    onLeftBegan: {
                        if swappedControls {
                            // Left behaves as right.
                            isMovingRight = true
                            playerState = .walking
                            playerFacingRight = true
                        } else {
                            isMovingLeft = true
                            playerState = .walking
                            playerFacingRight = false
                        }
                    },
                    onLeftEnded: {
                        if swappedControls {
                            isMovingRight = false
                            if !isMovingLeft { playerState = .idle }
                        } else {
                            isMovingLeft = false
                            if !isMovingRight { playerState = .idle }
                        }
                    },
                    onRightBegan: {
                        if swappedControls {
                            // Right behaves as left.
                            isMovingLeft = true
                            playerState = .walking
                            playerFacingRight = false
                        } else {
                            isMovingRight = true
                            playerState = .walking
                            playerFacingRight = true
                        }
                    },
                    onRightEnded: {
                        if swappedControls {
                            isMovingLeft = false
                            if !isMovingRight { playerState = .idle }
                        } else {
                            isMovingRight = false
                            if !isMovingLeft { playerState = .idle }
                        }
                    },
                    onJumpBegan: {
                        if isOnGround {
                            playerVelocity.y = jumpForce
                            isOnGround = false
                            playerState = .jumping
                        }
                    },
                    onJumpEnded: { }
                )
                .zIndex(3)
                // ...existing overlays or controls...
                
                // NEW: Add death overlay
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
                            levelManager.incrementDeathCount(for: 4)
                            addDeathNote(in: geometry)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isDead = false
                            }
                        }
                }
                
                // NEW: Add level complete overlay
                if isLevelComplete {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .zIndex(4)
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
                                showBSOD = true // Show BSOD instead of direct transition
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
                
                // NEW: Back to Map button
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

                // NEW: Dark overlay with torch effect and glowing text
                if isDarkMode {
                    ZStack {
                        // Existing dark overlay with torch effect
                        Canvas { context, size in
                            // Draw dark background
                            context.fill(
                                Path(CGRect(origin: .zero, size: size)),
                                with: .color(.black)
                            )
                            
                            // Create torch effect
                            let torchRadius: CGFloat = 100
                            let circle = Path(ellipseIn: CGRect(
                                x: torchPosition.x - torchRadius,
                                y: torchPosition.y - torchRadius,
                                width: torchRadius * 2,
                                height: torchRadius * 2
                            ))
                            
                            context.blendMode = .destinationOut
                            
                            // Use CGFloat instead of Float for the torch effect
                            context.drawLayer { ctx in
                                for radius in stride(from: CGFloat(0), to: torchRadius, by: CGFloat(1)) {
                                    let alpha = 1 - (radius / torchRadius)
                                    ctx.opacity = alpha
                                    
                                    let currentRadius = torchRadius - radius
                                    let circlePath = Path(ellipseIn: CGRect(
                                        x: torchPosition.x - currentRadius,
                                        y: torchPosition.y - currentRadius,
                                        width: currentRadius * 2,
                                        height: currentRadius * 2
                                    ))
                                    
                                    ctx.fill(circlePath, with: .color(.white))
                                }
                            }
                        }
                        
                        // Add glowing text when dark mode is active
                        if showGlowingText {
                            Text(glowingText)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                                .shadow(color: .green, radius: 10, x: 0, y: 0)
                                .shadow(color: .green, radius: 20, x: 0, y: 0)
                                .transition(.opacity)
                                .position(glowingTextPosition)  // Use the new position constant
                        }
                    }
                    .allowsHitTesting(false)
                    .zIndex(2000)
                }

                // UPDATED: BSOD overlay with X button
                if showBSOD {
                    ZStack {
                        Image("bsod")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                        
                        if showXButton {
                            Button(action: {
                                // Show troll message instead of closing BSOD
                                withAnimation {
                                    showTrollMessage = true
                                    // Hide message after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showTrollMessage = false
                                    }
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            .position(x: geometry.size.width - 50, y: 50)
                            .transition(.opacity)
                        }

                        // Troll message overlay
                        if showTrollMessage {
                            Text("Nice try, wait for machine to troll you")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(10)
                                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                        }
                    }
                    .zIndex(3000)
                    .onAppear {
                        // Show X button after 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.easeIn(duration: 0.3)) {
                                showXButton = true
                            }
                        }
                        
                        // Calculate ML insights and transition after BSOD
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            withAnimation {
                                showBSOD = false
                                totalTimeSpent = Date().timeIntervalSince(levelStartTime)
                                
                                // Calculate ML insights
                                predictionMessage = MLInsights.getPredictionMessage(
                                    level: 4,
                                    totalDeaths: deathCount,
                                    levelDeaths: currentLevelDeaths,
                                    hesitationCount: hesitationCount,
                                    timeSpent: totalTimeSpent,
                                    internalErrors: nil,
                                    timesFooled: timesFooled,
                                    playerTypeClassifier: typeClassifier,
                                    frustrationModel: frustrationModel
                                )
                            }
                        }
                    }
                }

                // Add ML insights overlay after BSOD
                if !showBSOD && predictionMessage != nil {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .zIndex(3001)
                    
                    VStack(spacing: 20) {
                        Text(predictionMessage!)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                        
                        Button("Enter Secret Level") {
                            withAnimation {
                                levelManager.currentState = .secretLevel
                            }
                        }
                        .font(.system(size: 24, weight: .bold))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .zIndex(3002)
                }
            }
        }
        .onAppear {
            levelStartTime = Date()
        }
    }
    
    // NEW: Update physics including gravity and horizontal movement.
    private func updatePhysics(in geometry: GeometryProxy) {
        if !isOnGround {
            playerVelocity.y += gravity
        }
        if isMovingLeft {
            playerPosition.x -= moveSpeed
        }
        if isMovingRight {
            playerPosition.x += moveSpeed
        }
        
        let newY = playerPosition.y + playerVelocity.y
        
        // Simple collision with platform4 (assuming platform top)
        let platformTop = platform4Position.y - platform4Size.height / 2
        if newY >= platformTop - 35 { // 35: half player height adjustment
            playerPosition.y = platformTop - 35
            playerVelocity.y = 0
            isOnGround = true
        } else {
            playerPosition.y = newY
            isOnGround = false
        }
        
        // NEW: Check collision with coffee1.
        let coffee1Frame = CGRect(
            x: coffee1Position.x - coffee1Size.width/2,
            y: coffee1Position.y - coffee1Size.height/2,
            width: coffee1Size.width,
            height: coffee1Size.height
        )
        let playerFrame = CGRect(
            x: playerPosition.x - 25,
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        if playerFrame.intersects(coffee1Frame) && !swappedControls {
            swappedControls = true
            showSwappedMessage = true
            if !hasBeenFooledBy.contains("coffee1") {
                timesFooled += 1
                hasBeenFooledBy.insert("coffee1")
                debugLog("Fooled by coffee1: Controls swapped!")
            }
            // Stop the player and wait for new input.
            playerVelocity = .zero
            isMovingLeft = false
            isMovingRight = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSwappedMessage = false
            }
        }

        // Add coffee3 collision check
        let coffee3Frame = CGRect(
            x: coffee3Position.x - coffee3Size.width/2,
            y: coffee3Position.y - coffee3Size.height/2,
            width: coffee3Size.width,
            height: coffee3Size.height
        )
        if playerFrame.intersects(coffee3Frame) {
            if !hasBeenFooledBy.contains("coffee3") {
                timesFooled += 1
                hasBeenFooledBy.insert("coffee3")
                debugLog("Fooled by coffee3!")
            }
        }

        // Update rejected3 collision check
        let rejected3Frame = CGRect(
            x: rejected3Position.x - rejected3Size.width/2,
            y: rejected3Position.y - rejected3Size.height/2,
            width: rejected3Size.width,
            height: rejected3Size.height
        )
        if playerFrame.intersects(rejected3Frame) {
            if !hasBeenFooledBy.contains("rejected3") {
                timesFooled += 1
                hasBeenFooledBy.insert("rejected3")
                debugLog("Fooled by rejected3!")
            }
        }
        
        // Reset player if out of bounds
        if playerPosition.y > geometry.size.height + 100 {
            handleDeath(in: geometry)
        }
        // NEW: When player reaches x <= 200, trigger bin animation.
        if playerPosition.x <= 300 && homeVisible {
            homeVisible = false
            showBin = true
            // Animate bin upward from platform4 bottom to homePosition.
            withAnimation(Animation.easeOut(duration: 1.0)) {
                binPosition = homePosition
            }
        }

        // Check bin collision
        let binFrame = CGRect(
            x: binPosition.x - binSize.width/2,
            y: binPosition.y - binSize.height/2,
            width: binSize.width,
            height: binSize.height
        )
        
        if playerFrame.intersects(binFrame) && showBin {
            // Trigger dark mode and show glowing text with delay
            withAnimation(.easeInOut(duration: 1.0)) {
                isDarkMode = true
            }
            // Show glowing text after dark mode transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showGlowingText = true
                }
            }
        }

        // NEW: Check for glowing text collision
        if isDarkMode && showGlowingText {
            let textBounds = CGRect(
                x: glowingTextPosition.x - glowingTextSize.width/2,
                y: glowingTextPosition.y - glowingTextSize.height/2,
                width: glowingTextSize.width,
                height: glowingTextSize.height
            )
            
            let playerBounds = CGRect(
                x: playerPosition.x - 25,
                y: playerPosition.y - 35,
                width: 50,
                height: 70
            )
            
            if playerBounds.intersects(textBounds) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showBSOD = true
                }
            }
        }
    }
    
    // NEW: Update player state based on movement.
    private func updatePlayerState() {
        if isDead { return }

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
            debugLog("Entered hesitation zone")
        }
        
        // Check for hesitation only when in zone and not moving
        if isInHesitationZone && !isMovingLeft && !isMovingRight && isOnGround {
            if let startTime = hesitationStartTime {
                let currentTime = Date()
                let hesitationDuration = currentTime.timeIntervalSince(startTime)
                
                if hesitationDuration >= hesitationThreshold {
                    hesitationCount += 1
                    hesitationStartTime = currentTime  // Reset timer after counting hesitation
                    debugLog("Hesitation detected! Count: \(hesitationCount)")
                }
            }
        } else if !isInHesitationZone {
            hesitationStartTime = nil  // Reset timer when moving or outside zone
        }

        if !isOnGround {
            playerState = .jumping
        } else if isMovingLeft || isMovingRight {
            playerState = .walking
        } else {
            playerState = .idle
        }
    }
    
    // NEW: Update running animation frame
    private func updateAnimation() {
        if playerState == .walking {
            let now = Date()
            if now.timeIntervalSince(lastAnimationTime) >= animationInterval {
                walkFrame = (walkFrame % 4) + 1  // Assumes 4 running frames.
                lastAnimationTime = now
            }
        } else {
            walkFrame = 1
        }
    }
    
    // NEW: Function to update rejected assets vertical movement
    private func updateRejected() {
        // Update rejected1
        if rejected1MovingUp {
            rejected1Position.y -= rejected1Speed
            if rejected1Position.y <= rejected1MaxTop {
                rejected1MovingUp = false
            }
        } else {
            rejected1Position.y += rejected1Speed
            if rejected1Position.y >= rejected1MaxBottom {
                rejected1MovingUp = true
            }
        }
        // Update rejected2
        if rejected2MovingUp {
            rejected2Position.y -= rejected2Speed
            if rejected2Position.y <= rejected2MaxTop {
                rejected2MovingUp = false
            }
        } else {
            rejected2Position.y += rejected2Speed
            if rejected2Position.y >= rejected2MaxBottom {
                rejected2MovingUp = true
            }
        }
        // Update rejected3
        if rejected3MovingUp {
            rejected3Position.y -= rejected3Speed
            if rejected3Position.y <= rejected3MaxTop {
                rejected3MovingUp = false
            }
        } else {
            rejected3Position.y += rejected3Speed
            if rejected3Position.y >= rejected3MaxBottom {
                rejected3MovingUp = true
            }
        }
    }
    
    // NEW: Reset player's position.
    private func resetPlayer() {
        playerPosition = CGPoint(x: 1200, y: 300) // Updated reset to x = 1200 remains
        playerVelocity = .zero
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
        playerFacingRight = false  // Reset to face left
        hasBeenFooledBy.removeAll() // Allow player to be fooled again after death
    }
    
    // NEW: Add death note function
    private func addDeathNote(in geometry: GeometryProxy) {
        let notes = ["note1", "note2", "note3", "note4", "note5"]
        let noteIndex = deathCount % notes.count
        let randomX = CGFloat.random(in: 0...geometry.size.width)
        let randomY = CGFloat.random(in: 0...geometry.size.height)
        let rotation = Double.random(in: -30...30)
        
        levelManager.addDeathNote(
            for: 4,
            note: notes[noteIndex],
            position: CGPoint(x: randomX, y: randomY),
            rotation: rotation
        )
    }
    
    // NEW: Add handleDeath function
    private func handleDeath(in geometry: GeometryProxy) {
        isDead = true
        resetPlayer()
    }

    // Update checkHomeCollision() to include ML insights
    private func checkHomeCollision() {
        let playerBounds = CGRect(
            x: playerPosition.x - 25,
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        let homeBounds = CGRect(
            x: homePosition.x - homeSize.width/2,
            y: homePosition.y - homeSize.height/2,
            width: homeSize.width,
            height: homeSize.height
        )
        
        if playerBounds.intersects(homeBounds) {
            isLevelComplete = true
            isMovingLeft = false
            isMovingRight = false
            playerVelocity = .zero
            playerState = .idle
            
            // Calculate insights when reaching home
            totalTimeSpent = Date().timeIntervalSince(levelStartTime)
            
            predictionMessage = MLInsights.getPredictionMessage(
                level: 4,
                totalDeaths: deathCount,
                levelDeaths: currentLevelDeaths,
                hesitationCount: hesitationCount,
                timeSpent: totalTimeSpent,
                internalErrors: nil,
                timesFooled: timesFooled,
                playerTypeClassifier: typeClassifier,
                frustrationModel: frustrationModel
            )
        }
    }
}

struct Level4_Previews: PreviewProvider {
    static var previews: some View {
        Level4()
            .environmentObject(LevelManager()) // NEW: Inject LevelManager instance
    }
}

