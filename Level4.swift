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
    private var deathNotes: [(note: String, position: CGPoint, rotation: Double)] {
        levelManager.getDeathNotes(for: 4)
    }
    
    // NEW: Adjustable settings for 'platform4'
    private let platform4Size: CGSize = CGSize(width: 1200, height: 50)    // Adjust as needed.
    private let platform4Position: CGPoint = CGPoint(x: 600, y: 550)        // Adjust as needed.
    
    // NEW: Adjustable settings for three 'coffee' assets
    private let coffee1Size: CGSize = CGSize(width: 22, height: 35)
    private let coffee1Position: CGPoint = CGPoint(x: 780, y: 500)
    
    private let coffee2Size: CGSize = CGSize(width: 22, height: 35)
    private let coffee2Position: CGPoint = CGPoint(x: 860, y: 500)
    
    private let coffee3Size: CGSize = CGSize(width: 22, height: 35)
    private let coffee3Position: CGPoint = CGPoint(x: 940, y: 500)
    
    // NEW: Player state variables and physics constants
    @State private var playerState: PlayerState = .idle
    @State private var playerFacingRight = false  // Changed from true to false for left-facing start
    @State private var playerPosition = CGPoint(x: 1100, y: 300)           // Adjust starting position
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
    
    private let rejected1Size: CGSize = CGSize(width: 210, height: 100)
    private let rejected1Start: CGPoint = CGPoint(x: 250, y: 400)
    private let rejected1Speed: CGFloat = 9.0
    private let rejected1MaxTop: CGFloat = 200
    private let rejected1MaxBottom: CGFloat = 650
    private let rejected1Rotation: Angle = .degrees(90)
    
    private let rejected2Size: CGSize = CGSize(width: 210, height: 100)
    private let rejected2Start: CGPoint = CGPoint(x: 450, y: 400)
    private let rejected2Speed: CGFloat = 7.0
    private let rejected2MaxTop: CGFloat = 200
    private let rejected2MaxBottom: CGFloat = 650
    private let rejected2Rotation: Angle = .degrees(90)
    
    private let rejected3Size: CGSize = CGSize(width: 210, height: 100)
    private let rejected3Start: CGPoint = CGPoint(x: 650, y: 400)
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
    private let homePosition: CGPoint = CGPoint(x: 95, y: 480)       // Adjust as needed.
    
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
    private let glowingTextPosition = CGPoint(x: 580, y: 340)  // Adjust these values as needed
    
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
        CGRect(x: 900, y: 405, width: 130, height: 120),  // Before coffee3
        CGRect(x: 700, y: 405, width: 100, height: 120),   // Before obstacle3
        CGRect(x: 500, y: 405, width: 100, height: 120),   // Before obstacle2
        CGRect(x: 300, y: 405, width: 100, height: 120)    // Before obstacle1
    ]
    @State private var isInHesitationZone = false
    @State private var hesitationStartTime: Date?
    private let hesitationThreshold: TimeInterval = 1.0
    
    // Add new state variable to track if obstacles should be visible
    @State private var showObstacles = true

    // Add state for tracking starting death count
    @State private var startingDeathCount: Int = 0

    // Update deathCount computed property to include all deaths from previous levels
    private var deathCount: Int {
        levelManager.getTotalDeathCount()  // Get total deaths across all levels
    }

    init() {
        _rejected1Position = State(initialValue: rejected1Start)
        _rejected2Position = State(initialValue: rejected2Start)
        _rejected3Position = State(initialValue: rejected3Start)
        // Initialize binPosition at the bottom of platform4.
        let platform4Bottom = platform4Position.y + platform4Size.height/2  // e.g. 575
        _binPosition = State(initialValue: CGPoint(x: homePosition.x, y: platform4Bottom))
    }
    
    // Add function to import Level 3 death notes
    private func importLevel3Notes() {
        let level3Notes = levelManager.getDeathNotes(for: 3)
        for note in level3Notes {
            levelManager.addDeathNote(
                for: 4,
                note: note.note,
                position: note.position,
                rotation: note.rotation
            )
        }
        debugLog("Imported \(level3Notes.count) death notes from Level 3")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background
                Color.white.ignoresSafeArea()
                    .zIndex(0)
                
                // Death Notes Layer - always show without condition
                ForEach(deathNotes.indices, id: \.self) { index in
                    Image(deathNotes[index].note)
                        .resizable()
                        .frame(width: 150, height: 150)
                        .position(deathNotes[index].position)
                        .rotationEffect(.degrees(deathNotes[index].rotation))
                        .opacity(0.7)  // Fixed opacity
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2)
                        .zIndex(0.1)  // Keep consistently behind all game elements
                        .allowsHitTesting(false)
                }
                
                // Platform (z-index: 1)
                Image("platform4")
                    .resizable()
                    .frame(width: platform4Size.width, height: platform4Size.height)
                    .position(platform4Position)
                    .zIndex(1)
                
                // Death Counter overlay
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
                if !isDarkMode && showObstacles {  // Add showObstacles condition
                    // Show regular game elements
                    Group {
                        // Coffee assets
                        Image("coffee")
                            .resizable()
                            .frame(width: coffee1Size.width, height: coffee1Size.height)
                            .position(coffee1Position)
                            .zIndex(3)
                        Image("coffee")
                            .resizable()
                            .frame(width: coffee2Size.width, height: coffee2Size.height)
                            .position(coffee2Position)
                            .zIndex(3)
                        Image("coffee")
                            .resizable()
                            .frame(width: coffee3Size.width, height: coffee3Size.height)
                            .position(coffee3Position)
                            .zIndex(3)
                        
                        // Rejected assets
                        Image("rejected")
                            .resizable()
                            .frame(width: rejected1Size.width, height: rejected1Size.height)
                            .rotationEffect(rejected1Rotation)
                            .position(rejected1Position)
                            .zIndex(2)
                        Image("rejected")
                            .resizable()
                            .frame(width: rejected2Size.width, height: rejected2Size.height)
                            .rotationEffect(rejected2Rotation)
                            .position(rejected2Position)
                            .zIndex(2)
                        Image("rejected")
                            .resizable()
                            .frame(width: rejected3Size.width, height: rejected3Size.height)
                            .rotationEffect(rejected3Rotation)
                            .position(rejected3Position)
                            .zIndex(2)
                    }
                }
                
                // ...existing code...
                // Add actual collision hitbox visualization for rejected1 and rejected2

                // ...existing code...
                
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
                    .zIndex(4)
                    .onReceive(physicsTimer) { _ in
                        updatePhysics(in: geometry)
                        updatePlayerState()
                        updateAnimation()
                        updateRejected()  // NEW: update rejected assets movement
                        if isDarkMode {
                            torchPosition = playerPosition // Update torch position to follow player
                        }
                    }
                
                // Add player collision box visualization
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 70) // Match the collision box size used in physics
                    .position(playerPosition)
                    .zIndex(0.5)

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
                            // Automatically clear death overlay after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
                
                // UPDATED: BSOD overlay with adjusted position
                if showBSOD {
                    ZStack {
                        Image("bsod")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(x: -50) // Move BSOD image 50 points to the left
                        
                        // Rest of BSOD overlay content
                        if showXButton {
                            Button(action: {
                                withAnimation {
                                    showTrollMessage = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showTrollMessage = false
                                    }
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            .position(x: geometry.size.width - 70, y: 50) // Adjust X button position
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
                    Color.black.opacity(1.0)
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
            // Store initial death count to calculate new deaths in this level
            startingDeathCount = levelManager.getTotalDeathCount()
            levelStartTime = Date()
            currentLevelDeaths = 0  // Reset level-specific death counter
            debugLog("Level 4 started - Initial death count: \(startingDeathCount)")
            
            // Import death notes from Level 3 with a staggered effect
            let level3Notes = levelManager.getDeathNotes(for: 3)
            
            // Import each note with a slight delay and random position adjustment
            for (index, note) in level3Notes.enumerated() {
                // Add some randomness to the position to avoid exact overlap
                let randomOffset = CGPoint(
                    x: CGFloat.random(in: -50...50),
                    y: CGFloat.random(in: -50...50)
                )
                let newPosition = CGPoint(
                    x: note.position.x + randomOffset.x,
                    y: note.position.y + randomOffset.y
                )
                
                // Stagger the import of notes
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    levelManager.addDeathNote(
                        for: 4,
                        note: note.note,
                        position: newPosition,
                        rotation: note.rotation + Double.random(in: -15...15)  // Add slight rotation variation
                    )
                }
            }
            
            debugLog("Imported \(level3Notes.count) death notes from Level 3")
            debugLog("Starting Level 4 with \(startingDeathCount) total deaths")
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
            if (!hasBeenFooledBy.contains("coffee1")) {
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
        
        // Check bin collision
        let binFrame = CGRect(
            x: binPosition.x - binSize.width/2,
            y: binPosition.y - binSize.height/2,
            width: binSize.width,
            height: binSize.height
        )
        
        if playerFrame.intersects(binFrame) && showBin {
            showObstacles = false
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
        
        // Only check obstacle collisions if they are visible
        if showObstacles {
            // Coffee3 collision check
            let coffee3Frame = CGRect(
                x: coffee3Position.x - coffee3Size.width/2,
                y: coffee3Position.y - coffee3Size.height/2,
                width: coffee3Size.width,
                height: coffee3Size.height
            )
            if playerFrame.intersects(coffee3Frame) {
                handleDeath(in: geometry)
                return
            }

            // Rejected1 collision check
            let rejected1Frame = CGRect(
                x: rejected1Position.x - rejected1Size.height/2, // Note: width and height are swapped due to rotation
                y: rejected1Position.y - rejected1Size.width/2,
                width: rejected1Size.height,
                height: rejected1Size.width
            )
            if playerFrame.intersects(rejected1Frame) {
                handleDeath(in: geometry)
                return
            }

            // Rejected2 collision check
            let rejected2Frame = CGRect(
                x: rejected2Position.x - rejected2Size.height/2, // Note: width and height are swapped due to rotation
                y: rejected2Position.y - rejected2Size.width/2,
                width: rejected2Size.height,
                height: rejected2Size.width
            )
            if playerFrame.intersects(rejected2Frame) {
                handleDeath(in: geometry)
                return
            }

            // Rejected3 collision check
            let rejected3Frame = CGRect(
                x: rejected3Position.x - rejected3Size.width/2,
                y: rejected3Position.y - rejected3Size.height/2,
                width: rejected3Size.width,
                height: rejected3Size.height
            )
            if playerFrame.intersects(rejected3Frame) {
                if (!hasBeenFooledBy.contains("rejected3")) {
                    timesFooled += 1
                    hasBeenFooledBy.insert("rejected3")
                    debugLog("Fooled by rejected3!")
                }
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

    // Move these functions outside of updatePhysics
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

    private func resetPlayer() {
        playerPosition = CGPoint(x: 1100, y: 300) // Reset to starting position
        playerVelocity = .zero
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
        playerFacingRight = false
        hasBeenFooledBy.removeAll()
        swappedControls = false // Reset swapped controls state too
    }

    private func addDeathNote(in geometry: GeometryProxy) {
        let notes = ["note1", "note2", "note3", "note4", "note5"]
        let noteIndex = deathCount % notes.count
        
        // Keep notes within visible area with padding
        let padding: CGFloat = 100
        let randomX = CGFloat.random(in: padding...(geometry.size.width - padding))
        let randomY = CGFloat.random(in: padding...(geometry.size.height - padding))
        let rotation = Double.random(in: -30...30)
        
        // Add note immediately without any conditions
        levelManager.addDeathNote(
            for: 4,
            note: notes[noteIndex],
            position: CGPoint(x: randomX, y: randomY),
            rotation: rotation
        )
        debugLog("Added death note at position: (\(randomX), \(randomY))")
    }

    // Update the handleDeath function to manage the death overlay timing and ensure death note appears
    private func handleDeath(in geometry: GeometryProxy) {
        if isDead { return }
        
        // First increment death count and add death note
        levelManager.incrementDeathCount(for: 4)
        currentLevelDeaths += 1
        addDeathNote(in: geometry)  // Add death note before showing overlay
        resetPlayer()
        
        // Then show death overlay
        isDead = true
        debugLog("Death in Level 4 - Total deaths across all levels: \(deathCount)")
        
        // Clear death state after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isDead = false
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

    // Add the playerDied function to handle player death
    private func playerDied(in geometry: GeometryProxy) {
        isDead = true
        isMovingLeft = false
        isMovingRight = false
        playerVelocity = .zero
        
        // Add death note and increment death count
        currentLevelDeaths += 1
        levelManager.incrementDeathCount(for: 4)
        debugLog("Killed by rejected! Death count: \(currentLevelDeaths)")
        addDeathNote(in: geometry)
        
        // Handle player death animation and respawn
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            resetPlayer()
            isDead = false
        }
    }
    
    struct Level4_Previews: PreviewProvider {
        static var previews: some View {
            Level4()
                .environmentObject(LevelManager()) // NEW: Inject LevelManager instance
        }
    }
}
