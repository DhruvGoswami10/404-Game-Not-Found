import SwiftUI
import Combine

struct Level3: View {
    @EnvironmentObject private var levelManager: LevelManager
    // Added player-related state variables and constants:
    @State private var playerState: PlayerState = .idle
    @State private var playerFacingRight = true
    @State private var playerPosition = CGPoint(x: 200, y: 300)
    @State private var playerVelocity = CGPoint.zero
    @State private var isOnGround = true
    @State private var isMovingLeft = false
    @State private var isMovingRight = false
    @State private var isDead = false
    // NEW: Track level completion
    @State private var isLevelComplete = false
    @State private var walkFrame = 1
    @State private var lastAnimationTime = Date()
    // Added idleStartTime for idle-phone animation.
    @State private var idleStartTime = Date()
    // Added new touch counter.
    @State private var touchCount = 0
    @State private var predictionMessage: String? = nil  // NEW
    
    private let gravity: CGFloat = 0.8
    private let jumpForce: CGFloat = -15
    private let animationInterval: TimeInterval = 0.08
    let physicsTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    private let platformHeight: CGFloat = 50
    private let playerHeight: CGFloat = 90
    
    private var deathCount: Int {
        levelManager.getDeathCount(for: 3)
    }
    private var deathNotes: [(note: String, position: CGPoint, rotation: Double)] {
        levelManager.getDeathNotes(for: 3)
    }
    
    // Existing platform configurations:
    private let platforms = (
        plat: (           // Bottom Platform
            position: CGPoint(x: 650, y: 680),
            size: CGSize(width: 1150, height: 50)
        ),
        wall: (
            position: CGPoint(x: 100, y: 400),
            size: CGSize(width: 50, height: 450)
        ),
        roof: (
            position: CGPoint(x: 650, y: 200),
            size: CGSize(width: 1150, height: 50)
        )
    )
    // Added new 'Plat3-down':
    private let secondDown = (  // Middle Platform
        position: CGPoint(x: 775, y: 520),
        size: CGSize(width: 800, height: 50)
    )
    // Added new 'Plat3-wall':
    private let secondWall = (
        position: CGPoint(x: 1200, y: 400),
        size: CGSize(width: 50, height: 450)
    )
    
    // Add new platform configuration after existing platform configs
    private let platform3Extra = (      // Top Platform
        position: CGPoint(x: 525, y: 360),         // Adjust x/y position as needed
        size: CGSize(width: 800, height: 50)    // Adjust width/height as needed
    )
    
    // New enum to track eof movement phases.
    private enum EofPhase {
        case right, down, left, fading
    }
    
    // Configurable eof parameters.
    private let eofStartPosition: CGPoint = CGPoint(x: 150, y: 300)  // adjust starting position here
    private let eofSize: CGSize = CGSize(width: 120, height: 80)        // adjust size here
    private let eofTargetX: CGFloat = 1050   // move right until this x
    private let eofTargetY: CGFloat = 500   // then down until this y
    private let eofSpeedRight: CGFloat = 2  // adjust rightward speed here
    private let eofSpeedDown: CGFloat = 2   // adjust downward speed here
    private let eofSpeedLeft: CGFloat = 2   // adjust leftward speed here
    private let eofFadeSpeed: Double = 0.01 // adjust fade speed here
    
    // State variables for eof.
    @State private var eofPosition: CGPoint = .zero
    @State private var eofOpacity: Double = 1.0
    @State private var eofPhase: EofPhase = .right
    
    // Configurable home constants
    private var homePosition: CGPoint = CGPoint(x: 1120, y: 605) // Adjust as needed
    private let homeSize: CGSize = CGSize(width: 100, height: 100)   // Adjust as needed
    
    // NEW: Configurable spike constants
    //spike
    private var spikePosition: CGPoint = CGPoint(x: 400, y: 485)      // Adjust as needed
    private let spikeSize: CGSize = CGSize(width: 50, height: 35)        // Adjust as needed
    
    //spike2
    private var spike2Position: CGPoint = CGPoint(x: 600, y: 485)       // Adjust as needed
    private let spike2Size: CGSize = CGSize(width: 50, height: 35)         // Adjust as needed
    
    // NEW: spike3 - additional spike asset
    @State private var spike3Position: CGPoint = CGPoint(x: 800, y: 485)       // Adjust as needed
    private let spike3Size: CGSize = CGSize(width: 50, height: 35)         // Adjust as needed
    
    // NEW: Spike3 movement configuration
    private let spike3ActivationThreshold: CGFloat = 750    // Player x threshold to activate spike3 movement
    private let spike3TargetX: CGFloat = 900                  // Destination x for spike3
    private let spike3MoveSpeed: CGFloat = 10.0                // Movement speed
    
    // Add new states and types for terminal animation
    struct TerminalLine {
        let text: String
        let color: Color
        let isProgress: Bool
        let delay: Double
    }

    private enum TransitionState {
        case none
        case animating
        case complete
    }

    @State private var terminalLines: [TerminalLine] = []
    @State private var currentLine = 0
    @State private var progressValue: CGFloat = 0
    @State private var transitionState: TransitionState = .none
    @State private var showCursor = true
    
    // Add new state for typing animation
    @State private var typedCommand = ""
    private let promptText = "404User@Mac ~ % "
    private let commandToType = "pip install Level4.swift"
    private let typingInterval: TimeInterval = 0.05  // Adjust for faster/slower typing
    
    // Modify terminalSequence to use empty initial command
    private let terminalSequence = [
        TerminalLine(text: "", color: .white, isProgress: false, delay: 0.5),  // Empty initial command
        TerminalLine(text: "Collecting Level4.swift...", color: .white, isProgress: false, delay: 1.0),
        TerminalLine(text: "Downloading Level4.swift-1.0.0-py3-none-any.whl (404.0MB)", color: .white, isProgress: false, delay: 0.8),
        TerminalLine(text: "", color: .blue, isProgress: true, delay: 3.0), // Progress bar
        TerminalLine(text: "\nERROR: Could not find a version that satisfies the requirement Level4.swift", color: .red, isProgress: false, delay: 0.5),
        TerminalLine(text: "ERROR: No matching distribution found for Level4.swift", color: .red, isProgress: false, delay: 0.8),
        TerminalLine(text: "\nTraceback (most recent call last):", color: .red, isProgress: false, delay: 0.5),
        TerminalLine(text: "  File \"<stdin>\", line 1, in <module>", color: .red, isProgress: false, delay: 0.3),
        TerminalLine(text: "  File \"/usr/local/lib/python3.9/site-packages/pip/_internal/req/req_install.py\", line 444, in run", color: .red, isProgress: false, delay: 0.3),
        TerminalLine(text: "    raise ModuleNotFoundError(\"DependencyNotFound: Missing sense of logic\")", color: .red, isProgress: false, delay: 0.3),
        TerminalLine(text: "ModuleNotFoundError: DependencyNotFound: Missing sense of logic", color: .red, isProgress: false, delay: 1.0),
        TerminalLine(text: "\nERROR: Installation failed. Please update your sanity and try again.", color: .red, isProgress: false, delay: 1.0),
        TerminalLine(text: "\nInstalling backup package: Level4_BETA.swift...", color: .white, isProgress: false, delay: 0.8),
        TerminalLine(text: "", color: .blue, isProgress: true, delay: 1.5), // Second progress bar
        TerminalLine(text: "✅ SUCCESS: Level4.swift installed (somehow). Good luck.", color: .green, isProgress: false, delay: 2.0)
    ]
    
    // Add new button and secondEOF configuration
    // NEW: Button configuration
    private let buttonConfig = (
        size: CGSize(width: 170, height: 50),
        position: CGPoint(x: 230, y: 650),
        pressedOffset: CGFloat(20)  // How far button moves down when pressed
    )
    @State private var isButtonPressed = false
    
    // NEW: Second EOF configuration
    private let secondEofConfig = (
        size: CGSize(width: 120, height: 80),
        startPosition: CGPoint(x: 200, y: 650),
        endPosition: CGPoint(x: 1100, y: 650),  // Changed end position to x: 1100
        speed: CGFloat(5)
    )
    @State private var showSecondEof = false
    @State private var secondEofPosition: CGPoint
    
    init() {
        // Initialize eofPosition with eofStartPosition.
        _eofPosition = State(initialValue: eofStartPosition)
        _secondEofPosition = State(initialValue: secondEofConfig.startPosition)
    }
    
    // Add new state for progress animation
    @State private var activeProgressLine = -1
    @State private var progressValues: [CGFloat] = [0, 0]  // One for each progress bar

    // Add missing constant for movement speed:
    private let moveSpeed: CGFloat = 7

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
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
                
                // UPDATED: Death Notes Background Layer (same style as Level1/2)
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
                
                // ...existing background/platform visuals...
                // NEW: Red button should be rendered before platforms
                Rectangle()
                    .fill(Color.red)
                    .frame(width: buttonConfig.size.width, height: buttonConfig.size.height)
                    .position(x: buttonConfig.position.x, 
                             y: buttonConfig.position.y + (isButtonPressed ? buttonConfig.pressedOffset : 0))
                    .animation(.spring(), value: isButtonPressed)
                
                Image("Plat3-down")
                    .resizable()
                    .frame(width: platforms.plat.size.width, height: platforms.plat.size.height)
                    .position(platforms.plat.position)
                Image("Plat3-wall")
                    .resizable()
                    .frame(width: platforms.wall.size.width, height: platforms.wall.size.height)
                    .position(platforms.wall.position)
                Image("Plat3-roof")
                    .resizable()
                    .frame(width: platforms.roof.size.width, height: platforms.roof.size.height)
                    .position(platforms.roof.position)
                
                // Render the new Plat3-down:
                Image("Plat3-down")
                    .resizable()
                    .frame(width: secondDown.size.width, height: secondDown.size.height)
                    .position(secondDown.position)
                // Render the new Plat3-wall:
                Image("Plat3-wall")
                    .resizable()
                    .frame(width: secondWall.size.width, height: secondWall.size.height)
                    .position(secondWall.position)
                
                // Add new platform3 after existing platforms
                Image("Plat3-down")
                    .resizable()
                    .frame(width: platform3Extra.size.width, height: platform3Extra.size.height)
                    .position(platform3Extra.position)
                
                // NEW: Home Asset (adjustable size and position)
                Image("Home")
                    .resizable()
                    .frame(width: homeSize.width, height: homeSize.height)
                    .position(homePosition)
                    .zIndex(1)
                
                // NEW: Spike assets (adjustable size and position)
                Image("spike")
                    .resizable()
                    .frame(width: spikeSize.width, height: spikeSize.height)
                    .position(spikePosition)
                    .zIndex(1)
                Image("spike2")
                    .resizable()
                    .frame(width: spike2Size.width, height: spike2Size.height)
                    .position(spike2Position)
                    .zIndex(1)
                // NEW: Additional spike (spike3)
                Image("spike")
                    .resizable()
                    .frame(width: spike3Size.width, height: spike3Size.height)
                    .position(spike3Position)
                    .zIndex(1)
                
                // Re-added Player view with physics updates and new onTapGesture.
                Player(currentState: playerState, facingRight: playerFacingRight, walkFrame: walkFrame)
                    .position(playerPosition)
                    .onTapGesture {
                        touchCount += 1
                        if touchCount >= 3 {
                            handleDeath(in: geometry)
                        } else {
                            playerState = .hey
                            idleStartTime = Date()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if playerState == .hey {
                                    playerState = .idle
                                }
                            }
                        }
                    }
                    .onReceive(physicsTimer) { _ in
                        updatePhysics(in: geometry)
                        updatePlayerState()
                        updateAnimation()
                        updateEOF()  // update eof movement each frame
                        updateSpike3() // NEW: update spike3 movement
                    }
                
                // Render eof asset.
                Image("eof")
                    .resizable()
                    .frame(width: eofSize.width, height: eofSize.height)
                    .position(eofPosition)
                    .opacity(eofOpacity)
                
                // NEW: Add second EOF after first EOF
                if showSecondEof {
                    Image("eof")
                        .resizable()
                        .frame(width: secondEofConfig.size.width, height: secondEofConfig.size.height)
                        .position(secondEofPosition)
                }
                
                // Back to map button remains.
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
                
                // Re-enabled controls (callbacks can be enhanced as needed)
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
                        if !isLevelComplete {
                            isMovingLeft = true
                            playerState = .walking
                            playerFacingRight = false
                        }
                    },
                    onLeftEnded: {
                        if !isLevelComplete {
                            isMovingLeft = false
                            if (!isMovingRight) {
                                playerState = .idle
                                idleStartTime = Date()
                            }
                        }
                    },
                    onRightBegan: {
                        if !isLevelComplete {
                            isMovingRight = true
                            playerState = .walking
                            playerFacingRight = true
                        }
                    },
                    onRightEnded: {
                        if !isLevelComplete {
                            isMovingRight = false
                            if (!isMovingLeft) {
                                playerState = .idle
                                idleStartTime = Date()
                            }
                        }
                    },
                    onJumpBegan: {
                        if !isLevelComplete, isOnGround {
                            playerVelocity.y = jumpForce
                            isOnGround = false
                            playerState = .jumping
                            idleStartTime = Date()
                        }
                    },
                    onJumpEnded: { }
                )
                .zIndex(3)
                
                // NEW: Death Overlay (appears when isDead is true)
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
                            levelManager.incrementDeathCount(for: 3)  // Increment death count for level 3
                            addDeathNote(in: geometry)  // Add a death note
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isDead = false
                            }
                        }
                }
                
                // NEW: Level complete overlay
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
                
                // Terminal transition overlay
                if transitionState != .none {
                    Color.black
                        .ignoresSafeArea()
                        .zIndex(5)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        // Show prompt and typing animation for first line
                        HStack {
                            Text(promptText)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .regular, design: .monospaced))
                            Text(typedCommand)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .regular, design: .monospaced))
                            if currentLine == 0 {
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 16)
                                    .opacity(showCursor ? 1 : 0)
                            }
                        }
                        
                        // Show rest of terminal lines
                        ForEach(Array(terminalLines.enumerated()), id: \.0) { index, line in
                            if line.isProgress {
                                let progressIndex = terminalLines.prefix(index + 1).filter(\.isProgress).count - 1
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geo.size.width * progressValues[progressIndex])
                                        .frame(height: 20)
                                }
                                .frame(width: 300, height: 20)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(4)
                            } else {
                                HStack {
                                    Text(line.text)
                                        .foregroundColor(line.color)
                                        .font(.system(size: 16, weight: .regular, design: .monospaced))
                                    if index + 1 == currentLine {
                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(width: 8, height: 16)
                                            .opacity(showCursor ? 1 : 0)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .zIndex(6)
                }
                
                // In your main ZStack inside body, add at the end:
                if isLevelComplete {
                    Color.black.ignoresSafeArea()
                        .zIndex(4)
                        .onAppear {
                            // Run ML prediction when level is complete.
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
                                levelManager.currentState = .level(4)
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
    
    // Modified updatePhysics to include rigid collisions for wall, roof, and new secondWall:
    private func updatePhysics(in geometry: GeometryProxy) {
        if isLevelComplete { return } // NEW: Stop updating physics when level is complete
        if !isOnGround {
            playerVelocity.y += gravity
        }
        if isMovingLeft {
            playerPosition.x -= moveSpeed
            playerFacingRight = false
        }
        if isMovingRight {
            playerPosition.x += moveSpeed
            playerFacingRight = true
        }
        
        let newY = playerPosition.y + playerVelocity.y
        
        // Floor collision using first Plat3-down and secondDown:
        func checkCollision(with platform: (position: CGPoint, size: CGSize)) -> Bool {
            let platTop = platform.position.y - platform.size.height / 2
            let platLeft = platform.position.x - platform.size.width / 2
            let platRight = platform.position.x + platform.size.width / 2
            let playerLeft = playerPosition.x - 25
            let playerRight = playerPosition.x + 25
            return playerRight >= platLeft &&
                   playerLeft <= platRight &&
                   (playerPosition.y + 35) <= platTop &&
                   (newY + 35) >= platTop
        }
        
        // Floor collision using all platforms:
        if checkCollision(with: platforms.plat) {
            playerPosition.y = (platforms.plat.position.y - platforms.plat.size.height / 2) - 35
            playerVelocity.y = 0
            isOnGround = true
        } else if checkCollision(with: secondDown) {
            playerPosition.y = (secondDown.position.y - secondDown.size.height / 2) - 35
            playerVelocity.y = 0
            isOnGround = true
        } else if checkCollision(with: platform3Extra) {  // Add collision check for platform3Extra
            playerPosition.y = (platform3Extra.position.y - platform3Extra.size.height / 2) - 35
            playerVelocity.y = 0
            isOnGround = true
        } else if checkButtonCollision(newY: newY) {  // NEW: Add button collision check
            playerPosition.y = buttonConfig.position.y - buttonConfig.size.height/2 - 35
            playerVelocity.y = 0
            isOnGround = true
        } else {
            playerPosition.y = newY
            isOnGround = false
        }
        
        // New collision detection for wall and roof:
        let playerRect = CGRect(x: playerPosition.x - 25, y: playerPosition.y - 35, width: 50, height: 70)
        
        // Wall collision for first wall:
        let wallRect = CGRect(
            x: platforms.wall.position.x - platforms.wall.size.width / 2,
            y: platforms.wall.position.y - platforms.wall.size.height / 2,
            width: platforms.wall.size.width,
            height: platforms.wall.size.height
        )
        if playerRect.intersects(wallRect) {
            if isMovingRight {
                playerPosition.x = wallRect.minX - 25
            } else if isMovingLeft {
                playerPosition.x = wallRect.maxX + 25
            }
        }
        // Wall collision for secondWall:
        let secondWallRect = CGRect(
            x: secondWall.position.x - secondWall.size.width / 2,
            y: secondWall.position.y - secondWall.size.height / 2,
            width: secondWall.size.width,
            height: secondWall.size.height
        )
        if playerRect.intersects(secondWallRect) {
            if isMovingRight {
                playerPosition.x = secondWallRect.minX - 25
            } else if isMovingLeft {
                playerPosition.x = secondWallRect.maxX + 25
            }
        }
        
        // Roof collision (prevent player from moving upward through the roof)
        let roofRect = CGRect(
            x: platforms.roof.position.x - platforms.roof.size.width / 2,
            y: platforms.roof.position.y - platforms.roof.size.height / 2,
            width: platforms.roof.size.width,
            height: platforms.roof.size.height
        )
        if playerRect.intersects(roofRect) && playerVelocity.y < 0 {
            playerPosition.y = roofRect.maxY + 35
            playerVelocity.y = 0
        }
        
        if playerPosition.y > geometry.size.height + 100 {
            handleDeath(in: geometry)
        }
        checkHomeCollision()
    }
    
    // NEW: Add helper function for button collision
    private func checkButtonCollision(newY: CGFloat) -> Bool {
        let buttonTop = buttonConfig.position.y - buttonConfig.size.height/2
        let buttonLeft = buttonConfig.position.x - buttonConfig.size.width/2
        let buttonRight = buttonConfig.position.x + buttonConfig.size.width/2
        let playerLeft = playerPosition.x - 25
        let playerRight = playerPosition.x + 25
        
        // First check if player is directly above the button
        let isAboveButton = playerRight >= buttonLeft && 
                           playerLeft <= buttonRight &&
                           (playerPosition.y + 35) <= buttonTop &&
                           (newY + 35) >= buttonTop
        
        // Then check if player is making contact with the button
        let isOnButton = playerRight >= buttonLeft &&
                        playerLeft <= buttonRight &&
                        abs((playerPosition.y + 35) - buttonTop) < 10
        
        // Press button when player lands on it
        if isOnButton || isAboveButton {
            if !isButtonPressed && playerVelocity.y >= 0 {  // Only when moving downward or standing
                pressButton()
            }
        }
        
        return isAboveButton
    }

    // Function to help with debugging
    private func debugLog(_ message: String) {
        print(message)
    }
    
    private func checkHomeCollision() {
        let playerBounds = CGRect(
            x: playerPosition.x - 25,
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        // Use homePosition and homeSize for collision detection.
        let homeBounds = CGRect(
            x: homePosition.x - homeSize.width / 2,
            y: homePosition.y - homeSize.height / 2,
            width: homeSize.width,
            height: homeSize.height
        )
        if playerBounds.intersects(homeBounds) {
            isLevelComplete = true
            isMovingLeft = false
            isMovingRight = false
            playerVelocity = .zero
            playerState = .idle
            
            levelManager.unlockNextLevel()
            
            // Start terminal animation sequence
            startTerminalAnimation()
        }
    }
    
    private func handleDeath(in geometry: GeometryProxy) {
        isDead = true
        resetPosition()
    }
    
    private func resetPosition() {
        playerPosition = CGPoint(x: 200, y: 310)
        playerVelocity = .zero
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
        // Reset touch counter whenever player resets.
        touchCount = 0
    }
    
    private func updatePlayerState() {
        if isDead { return }
        if !isOnGround {
            playerState = .jumping
            idleStartTime = Date() // reset idle timer mid-air
        } else if isMovingLeft || isMovingRight {
            playerState = .walking
            idleStartTime = Date() // reset idle timer on movement
        } else {
            let idleTime = Date().timeIntervalSince(idleStartTime)
            // After 3 seconds idle (and not touched), show usingPhone animation.
            if idleTime > 3 {
                playerState = .usingPhone
            } else if playerState != .hey {
                playerState = .idle
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
    
    // New function to update eof along its path.
    private func updateEOF() {
        switch eofPhase {
        case .right:
            eofPosition.x += eofSpeedRight
            if eofPosition.x >= eofTargetX {
                eofPhase = .down
            }
        case .down:
            eofPosition.y += eofSpeedDown
            if eofPosition.y >= eofTargetY {
                eofPhase = .left
            }
        case .left:
            eofPosition.x -= eofSpeedLeft
            if eofPosition.x <= eofStartPosition.x {
                eofPhase = .fading
            }
        case .fading:
            eofOpacity -= eofFadeSpeed
            if eofOpacity < 0 {
                eofOpacity = 0
            }
        }
        
        // Update second EOF if active
        if showSecondEof {
            secondEofPosition.x += secondEofConfig.speed // Changed from -= to += to move right
            
            // Check if second EOF has reached end position
            if secondEofPosition.x >= secondEofConfig.endPosition.x {
                showSecondEof = false
                isButtonPressed = false  // Reset button state
            }
        }
    }
    
    // NEW: Function to update spike3 movement
    private func updateSpike3() {
        if playerPosition.x >= spike3ActivationThreshold, spike3Position.x < spike3TargetX {
            spike3Position.x += spike3MoveSpeed
        }
    }
    
    private func addDeathNote(in geometry: GeometryProxy) {
        let notes = ["note1", "note2", "note3", "note4", "note5"]
        let noteIndex = deathCount % notes.count
        let randomX = CGFloat.random(in: 0...geometry.size.width)
        let randomY = CGFloat.random(in: 0...geometry.size.height)
        let rotation = Double.random(in: -30...30)
        
        levelManager.addDeathNote(
            for: 3,
            note: notes[noteIndex],
            position: CGPoint(x: randomX, y: randomY),
            rotation: rotation
        )
    }
    
    // Add new function to handle terminal animation
    private func startTerminalAnimation() {
        transitionState = .animating
        
        // Start cursor blink timer
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.showCursor.toggle()
            }
            .store(in: &cancellables)
        
        // Start typing animation just for the command part
        for (index, char) in commandToType.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * typingInterval) {
                typedCommand += String(char)
            }
        }
        
        // Start rest of animation after typing completes
        let typingDuration = Double(commandToType.count) * typingInterval
        var totalDelay = typingDuration + 0.5  // Add small pause after typing
        
        // Skip first line since we handled it with typing animation
        for (index, line) in terminalSequence.dropFirst().enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                terminalLines.append(line)
                currentLine = index + 1  // +1 because we're showing typed command
                
                if line.isProgress {
                    activeProgressLine += 1
                    // Animate progress over the line's delay duration
                    withAnimation(.linear(duration: line.delay)) {
                        progressValues[activeProgressLine] = 1.0
                    }
                }
            }
            totalDelay += line.delay
        }
        
        // Transition to Level 4 after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 1.0) {
            withAnimation {
                transitionState = .complete
                levelManager.currentState = .level(4)
            }
        }
    }
    
    // Add property to store cancellables
    @State private var cancellables = Set<AnyCancellable>()
    
    // Update pressButton function
    private func pressButton() {
        if (!isButtonPressed) {
            withAnimation(.spring(duration: 0.3)) {  // Add animation duration
                isButtonPressed = true
            }
            showSecondEof = true
            secondEofPosition = secondEofConfig.startPosition
            debugLog("Button pressed!")
        }
    }

    // Add missing getPredictionMessage function:
    private func getPredictionMessage() -> String {
        return "ML Insights:\nPlayer Type: Unknown\nFrustration: 0/100"
    }
}

#Preview {
    Level3().environmentObject(LevelManager())
}

