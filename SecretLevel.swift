import SwiftUI

struct SecretLevel: View {
    @EnvironmentObject private var levelManager: LevelManager
    
    // Add player state variables
    @State private var playerState: PlayerState = .idle
    @State private var playerFacingRight = true
    @State private var playerPosition = CGPoint(x: 200, y: 480)
    @State private var playerVelocity = CGPoint.zero
    @State private var isOnGround = true
    @State private var isMovingLeft = false
    @State private var isMovingRight = false
    @State private var walkFrame = 1
    @State private var lastAnimationTime = Date()
    
    // Add new state and configuration for typing effect
    @State private var currentCommand = ""
    @State private var isTyping = false
    @State private var errorKillCount = 0
    
    // Configuration for command text
    private let commandConfig = (
        position: CGPoint(x: 900, y: 545),    // Position above intern
        size: CGFloat(16),                     // Font size
        typingSpeed: TimeInterval(0.05),       // Speed of typing
        commands: [
            "sudo rm -rf errors/*",            // Gibberish commands after first 4
            "ERROR: Permission denied",
            "./hack_errors.sh",
            "segmentation fault (core dumped)"
        ]
    )
    
    // Physics constants
    private let gravity: CGFloat = 0.8
    private let jumpForce: CGFloat = -15
    private let moveSpeed: CGFloat = 7
    private let animationInterval: TimeInterval = 0.08
    let physicsTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    // Platform configuration
    private let secretPlatConfig = (
        size: CGSize(width: 1200, height: 50),    // Adjust size as needed
        position: CGPoint(x: 600, y: 650)         // Adjust position as needed
    )

    // Add intern configuration
    private let internConfig = (
        size: CGSize(width: 40, height: 60),    // Adjust size as needed
        position: CGPoint(x: 900, y: 595)         // Adjust position as needed
    )
    
    // Update error code configurations to include all error codes
    private let errorConfigs = [
        (name: "401", size: CGSize(width: 160, height: 100), speed: CGFloat(7.0)),
        (name: "402", size: CGSize(width: 160, height: 100), speed: CGFloat(8.0)),
        (name: "403", size: CGSize(width: 160, height: 100), speed: CGFloat(9.0)),
        (name: "404", size: CGSize(width: 160, height: 100), speed: CGFloat(10.0)),
        (name: "405", size: CGSize(width: 160, height: 100), speed: CGFloat(6.0)),
        (name: "406", size: CGSize(width: 160, height: 100), speed: CGFloat(8.5)),
        (name: "407", size: CGSize(width: 160, height: 100), speed: CGFloat(7.5)),
        (name: "408", size: CGSize(width: 160, height: 100), speed: CGFloat(9.5)),
        (name: "409", size: CGSize(width: 160, height: 100), speed: CGFloat(8.0)),
        (name: "410", size: CGSize(width: 160, height: 100), speed: CGFloat(11.0))
    ]
    
    // State for error positions and velocities
    @State private var errorPositions: [CGPoint]
    @State private var errorVelocities: [CGPoint]
    
    // Add new state for active errors
    @State private var activeErrors: Set<Int> = []
    @State private var nextSpawnTime: Date = Date()
    
    // Spawn timing configuration
    private let initialSpawnDelay: TimeInterval = 3.0  // Time between first errors
    private let fastSpawnDelay: TimeInterval = 0.5     // Time between later errors
    private let speedupThreshold: Int = 4              // When to increase spawn rate
    
    // Error spawn timer
    let spawnTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // Add new state for intern typing
    @State private var isInternTyping = false
    @State private var lastKilledError = -1
    @State private var typingStartTime = Date()
    
    // Add typing configuration
    private let typingConfig = (
        characterDelay: 0.05,  // Delay between each character
        commandDelay: 1.0,     // Delay between commands
        position: CGPoint(x: 1150, y: 545)  // Position above intern
    )

    @State private var spawnErrorsEnabled: Bool = true  // NEW: Prevent errors from respawning after clearance

    // Track IDs of killed errors
    @State private var killedErrors = Set<Int>()

    // Add safe configuration
    private let safeConfig = (
        size: CGSize(width: 140, height: 80),  // Adjust size as needed
        position: CGPoint(x: 100, y: 460)      // Adjust position as needed
    )

    // Add credits state and configuration
    @State private var showCredits = false
    @State private var creditsOffset: CGFloat = 1000  // Start below screen
    @State private var shouldExitAfterCredits = false
    
    private let credits = [
        "THIS IS IT!",
        "",
        "",
        "Thank you for playing!",
        "(And suffering)",
        "",
        "",
        "**Official Submission for Apple Swift Student Challenge 2025**",
        "Built with SwiftUI, SpriteKit, Core ML, and pure chaos",
        "",
        "",
        "Game Version: 1.0 (Final Final Version)",
        "Development Time: 3 weeks and sleepless nights",
        "Energy Source: Coffee",
        "Deubgging Tool: Print statements and sheer willpower",
        "",
        "",
        "---- Credits ----",
        "",
        "Created By:",
        "Dhruv Goswami",
        "(A.K.A. The Developer who should have stopped at Level1.swift)",
        "",
        "",
        "Game Development Team:",
        "Just Me",
        "My Macbook Air",
        "That one bug that still exists somewhwere)",
        "",
        "",
        "Art and Design:",
        "Me again",
        "My iPad Pro",
        "I'm not an artist still tried my best studio",
        "",
        "",         
        "Music and Sound Effects:",
        "Random noises I found online",
        "My Mechanical Keyboard",
        "That one sound I regret adding",
        "Silence (Actually the best part of the game)",
        "",
        "",
        "ML Insights Team:",
        "A Bunch of Overconfiedent Algorithms",
        "Create ML and its best models",
        "",
        "",
        "Final debugLog:",
        "- Total Player Deaths: (comming soon using level manager)",
        "- Times fooled: (comming soon using level manager)", 
        "- Total times you hesitated: (comming soon using level manager)",
        "- Total time spent: (comming soon using level manager)",
        "",
        "",
        "",
        "🏆",
        "Achievement Unlocked:",
        "Damn you actually finished the game!",
        "",
        "",
        "------ THE END ------",
        "",
        "",
        "",
        "",
        "",
        "",
    ]

    init() {
        // Initialize positions and velocities arrays with 10 random positions
        _errorPositions = State(initialValue: Array(repeating: CGPoint.zero, count: 10))
        _errorVelocities = State(initialValue: Array(repeating: CGPoint.zero, count: 10))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Add intern before the platform
                Image("intern")
                    .resizable()
                    .frame(width: internConfig.size.width, height: internConfig.size.height)
                    .position(internConfig.position)
                    .onTapGesture {
                        handleInternTap()
                    }
                
                // Add secret platform
                Image("secretPlat")
                    .resizable()
                    .frame(width: secretPlatConfig.size.width, height: secretPlatConfig.size.height)
                    .position(secretPlatConfig.position)
                
                // Update error rendering to use activeErrors
                ForEach(Array(activeErrors), id: \.self) { index in
                    Image(errorConfigs[index].name)
                        .resizable()
                        .frame(width: errorConfigs[index].size.width, 
                               height: errorConfigs[index].size.height)
                        .position(errorPositions[index])
                }
                
                // Add player
                Player(currentState: playerState, facingRight: playerFacingRight, walkFrame: walkFrame)
                    .position(playerPosition)
                    .onReceive(physicsTimer) { _ in
                        updatePhysics(in: geometry)
                        updatePlayerState()
                        updateAnimation()
                        updateErrors(in: geometry)  // Always update errors
                        if !activeErrors.isEmpty && !isInternTyping {
                            startTypingNextCommand()
                        }
                    }
                
                // Add typing effect above intern
                Text(currentCommand)
                    .font(.system(size: commandConfig.size, weight: .regular, design: .monospaced))
                    .foregroundColor(.green)
                    .position(commandConfig.position)
                    .zIndex(2)
                
                // Controls
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
                    onLeftBegan: { isMovingLeft = true; playerState = .walking; playerFacingRight = false },
                    onLeftEnded: { isMovingLeft = false; if !isMovingRight { playerState = .idle } },
                    onRightBegan: { isMovingRight = true; playerState = .walking; playerFacingRight = true },
                    onRightEnded: { isMovingRight = false; if !isMovingLeft { playerState = .idle } },
                    onJumpBegan: {
                        if isOnGround {
                            playerVelocity.y = jumpForce
                            isOnGround = false
                            playerState = .jumping
                        }
                    },
                    onJumpEnded: { }
                )
                .zIndex(2)
                
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
                .position(x: 100, y: 50)
                .zIndex(2)

                // Add safe asset
                if !showCredits {
                    Image("safe")
                        .resizable()
                        .frame(width: safeConfig.size.width, height: safeConfig.size.height)
                        .position(safeConfig.position)
                }

                // Update credits overlay in body
                if showCredits {
                    Color.black
                        .ignoresSafeArea()
                        .zIndex(100)
                    
                    GeometryReader { geo in
                        ZStack {
                            VStack(spacing: 30) {
                                ForEach(credits, id: \.self) { line in
                                    Text(line)
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(width: geo.size.width)
                            // Make content taller to ensure smooth scrolling
                            .frame(minHeight: geo.size.height * 2)
                            .offset(y: creditsOffset)
                            .onAppear {
                                // Start from bottom of screen
                                creditsOffset = geo.size.height * 2
                                
                                // Animate to above screen
                                withAnimation(.linear(duration: 30)) {
                                    creditsOffset = -geo.size.height * 3
                                }
                                
                                // Transition after credits finish
                                DispatchQueue.main.asyncAfter(deadline: .now() + 31) {
                                    shouldExitAfterCredits = true
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .clipped() // Ensure content is clipped to screen bounds
                    }
                    .zIndex(101)
                }
            }
            .onReceive(spawnTimer) { currentTime in
                if currentTime >= nextSpawnTime {
                    if spawnErrorsEnabled {
                        spawnNextError()
                    }
                    
                    // Start typing command if we have 4 or more active errors
                    if activeErrors.count >= 4 && !isTyping {
                        startNextCommand()
                    }
                }
            }
        }
    }
    
    private func updatePhysics(in geometry: GeometryProxy) {
        // Apply gravity if not on ground
        if !isOnGround {
            playerVelocity.y += gravity
        }
        
        // Handle horizontal movement
        if isMovingLeft {
            playerPosition.x -= moveSpeed
        }
        if isMovingRight {
            playerPosition.x += moveSpeed
        }
        
        let newY = playerPosition.y + playerVelocity.y
        
        // Platform collision detection
        let platformTop = secretPlatConfig.position.y - secretPlatConfig.size.height/2
        let platformLeft = secretPlatConfig.position.x - secretPlatConfig.size.width/2
        let platformRight = secretPlatConfig.position.x + secretPlatConfig.size.width/2
        let playerLeft = playerPosition.x - 25
        let playerRight = playerPosition.x + 25
        
        if playerRight >= platformLeft && 
           playerLeft <= platformRight &&
           (playerPosition.y + 35) <= platformTop &&
           (newY + 35) >= platformTop {
            playerPosition.y = platformTop - 35
            playerVelocity.y = 0
            isOnGround = true
        } else {
            playerPosition.y = newY
            isOnGround = false
        }
        
        // Reset if fallen off screen
        if playerPosition.y > geometry.size.height + 100 {
            resetPosition()
        }

        checkSafeCollision()  // Add collision check
    }
    
    private func updatePlayerState() {
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
                walkFrame = (walkFrame % 4) + 1
                lastAnimationTime = now
            }
        }
    }
    
    // Add platform constraints for errors
    private var errorBounds: (minY: CGFloat, maxY: CGFloat, minX: CGFloat, maxX: CGFloat) {
        return (minY: 50,
                maxY: secretPlatConfig.position.y - secretPlatConfig.size.height,
                minX: 50,
                maxX: 1250)
    }

    // Modify randomStartPosition function
    private func randomStartPosition() -> CGPoint {
        return CGPoint(
            x: CGFloat.random(in: errorBounds.minX...errorBounds.maxX),
            y: CGFloat.random(in: errorBounds.minY...errorBounds.maxY)
        )
    }

    // Modify updateErrors function
    private func updateErrors(in geometry: GeometryProxy) {
        for index in activeErrors.sorted() {
            // Ensure safe index access
            guard index < errorPositions.count, index < errorConfigs.count else { continue }
            var newPos = CGPoint(
                x: errorPositions[index].x + errorVelocities[index].x,
                y: errorPositions[index].y + errorVelocities[index].y
            )
            var newVel = errorVelocities[index]
            
            // Bounce off horizontal bounds
            if newPos.x <= errorBounds.minX || newPos.x >= errorBounds.maxX {
                newVel.x = -newVel.x
                newPos.x = min(max(newPos.x, errorBounds.minX), errorBounds.maxX)
            }
            
            // Bounce off vertical bounds
            if newPos.y <= errorBounds.minY || newPos.y >= errorBounds.maxY {
                newVel.y = -newVel.y
                newPos.y = min(max(newPos.y, errorBounds.minY), errorBounds.maxY)
            }
            
            // Introduce slight random variation to simulate erratic motion
            let variation: CGFloat = 0.2
            newVel.x += CGFloat.random(in: -variation...variation)
            newVel.y += CGFloat.random(in: -variation...variation)
            
            // Normalize velocity to maintain constant speed.
            let speed = errorConfigs[index].speed
            let currentSpeed = sqrt(newVel.x * newVel.x + newVel.y * newVel.y)
            if currentSpeed != 0 {
                newVel = CGPoint(
                    x: newVel.x / currentSpeed * speed,
                    y: newVel.y / currentSpeed * speed
                )
            }
            
            errorPositions[index] = newPos
            errorVelocities[index] = newVel
        }
    }
    
    private func spawnNextError() {
        // Don't spawn if all errors are active
        guard activeErrors.count < errorConfigs.count else { return }
        
        // Get available error indices
        let availableIndices = Set(0..<errorConfigs.count).subtracting(activeErrors).subtracting(killedErrors)
        if let newIndex = availableIndices.randomElement() {
            // Initialize position and velocity for new error
            errorPositions[newIndex] = randomStartPosition()
            errorVelocities[newIndex] = randomInitialVelocity(for: newIndex)
            
            // Add to active errors
            activeErrors.insert(newIndex)
            
            // Set next spawn time based on number of active errors
            let delay = activeErrors.count >= speedupThreshold ? fastSpawnDelay : initialSpawnDelay
            nextSpawnTime = Date().addingTimeInterval(delay)
        }
    }
    
    // Helper function to generate initial velocity
    private func randomInitialVelocity(for index: Int) -> CGPoint {
        let speed = errorConfigs[index].speed
        let angle = CGFloat.random(in: 0...(2 * .pi))
        return CGPoint(
            x: cos(angle) * speed,
            y: sin(angle) * speed
        )
    }
    
    private func resetPosition() {
        playerPosition = CGPoint(x: 200, y: 300)
        playerVelocity = .zero
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        playerState = .idle
    }
    
    // Add function to handle typing effect
    private func startNextCommand() {
        guard errorKillCount < commandConfig.commands.count && !isTyping else { return }
        
        isTyping = true
        currentCommand = ""
        let command = commandConfig.commands[errorKillCount]
        
        // Type each character with delay
        for (index, char) in command.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + commandConfig.typingSpeed * Double(index)) {
                currentCommand += String(char)
                
                // When command is complete, execute it
                if currentCommand == command {
                    executeCommand()
                }
            }
        }
    }

    // Add function to execute commands
    private func executeCommand() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if errorKillCount < 4 {
                // Extract error number from command
                if let errorNum = currentCommand.components(separatedBy: "_").last,
                   let index = activeErrors.firstIndex(where: { errorConfigs[$0].name == errorNum }) {
                    // Remove the error
                    activeErrors.remove(at: index)
                }
            }
            
            // Clear command and prepare for next one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentCommand = ""
                isTyping = false
                errorKillCount += 1
            }
        }
    }

    // Add function to start typing next command
    private func startTypingNextCommand() {
        guard !isInternTyping else { return }
        let command: String
        var errorIndex: Int? = nil
        if errorKillCount < 4 {
            // Kill command for active error
            guard let firstError = activeErrors.sorted().first,
                  firstError < errorConfigs.count else { return }
            errorIndex = firstError
            command = "kill -9 ERROR_" + errorConfigs[firstError].name
        } else {
            // After 4, use gibberish commands
            let gibberish = commandConfig.commands
            let idx = (errorKillCount - 4) % gibberish.count
            command = gibberish[idx]
        }
        isInternTyping = true
        currentCommand = ""
        for (i, char) in command.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + commandConfig.typingSpeed * Double(i)) {
                self.currentCommand.append(char)
                if self.currentCommand == command {
                    self.executeCommand(for: errorIndex)
                }
            }
        }
    }

    // Add function to execute command
    private func executeCommand(for errorIndex: Int?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let index = errorIndex, self.errorKillCount < 4 {
                self.activeErrors.remove(index)
                // Add to killedErrors so it won't be respawned
                self.killedErrors.insert(index)
            }
            self.currentCommand = ""
            self.isInternTyping = false
            self.errorKillCount += 1
        }
    }

    // Modify the intern tap handler to kill one error at a time:
    private func handleInternTap() {
        if isInternTyping {
            isInternTyping = false
            currentCommand = ""
        }
        killNextError()  // Call the new single-error kill function.
    }
    
    // New function to kill only the first active error.
    private func killNextError() {
        guard let errorIndex = activeErrors.sorted().first, errorIndex < errorConfigs.count else { return }
        isInternTyping = true
        currentCommand = ""
        let command = "kill -9 ERROR_" + errorConfigs[errorIndex].name
        for (i, char) in command.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + commandConfig.typingSpeed * Double(i)) {
                self.currentCommand.append(char)
                if self.currentCommand == command {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.activeErrors.remove(errorIndex)
                        // Add to killedErrors so it won't be respawned
                        self.killedErrors.insert(errorIndex)
                        self.currentCommand = ""
                        self.isInternTyping = false
                        // Disable any respawn if cleared
                        if self.activeErrors.isEmpty {
                            self.spawnErrorsEnabled = false
                        }
                    }
                }
            }
        }
    }

    
    // New function to sequentially kill all active errors:
    private func killAllActiveErrors() {
        let errorsToKill = activeErrors.sorted()
        guard !errorsToKill.isEmpty else {
            spawnErrorsEnabled = false  // Disable further spawns if no error exists
            return
        }
        isInternTyping = true
        var totalDelay: TimeInterval = 0
        for errorIndex in errorsToKill {
            guard errorIndex < errorConfigs.count else { continue }
            let command = "kill -9 ERROR_" + errorConfigs[errorIndex].name
            // Type each character of the command
            for (i, char) in command.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + commandConfig.typingSpeed * Double(i)) {
                    self.currentCommand.append(char)
                }
            }
            let commandDuration = commandConfig.typingSpeed * Double(command.count)
            totalDelay += commandDuration + 0.3  // Pause after each command
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                self.activeErrors.remove(errorIndex)
                // Add to killedErrors so it won't be respawned
                self.killedErrors.insert(errorIndex)
                self.currentCommand = ""
                // When processing the last error, end typing mode.
                if errorIndex == errorsToKill.last {
                    self.isInternTyping = false
                    // NEW: Disable further error spawning once all errors are cleared
                    self.spawnErrorsEnabled = false
                }
            }
        }
    }

    private func checkSafeCollision() {
        let playerBounds = CGRect(
            x: playerPosition.x - 25,
            y: playerPosition.y - 35,
            width: 50,
            height: 70
        )
        
        let safeBounds = CGRect(
            x: safeConfig.position.x - safeConfig.size.width/2,
            y: safeConfig.position.y - safeConfig.size.height/2,
            width: safeConfig.size.width,
            height: safeConfig.size.height
        )
        
        if playerBounds.intersects(safeBounds) {
            withAnimation(.easeInOut(duration: 1.0)) {
                showCredits = true
            }
        }
    }
}

#Preview {
    SecretLevel()
        .environmentObject(LevelManager())
}

