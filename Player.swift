import SwiftUI

enum PlayerState {
    case idle
    case walking
    case jumping
    case usingPhone
    case hey  // Add new state
}

private let frameSize: [String: (CGFloat, CGFloat)] = [
    "idle": (35, 70),
    "step-1": (50, 70),
    "step-2": (50, 70),
    "step-3": (50, 70), //width, height
    "step-4": (50, 70),
    "jump": (50, 70),
    "idle-phone": (45, 70),
    "hey": (75, 70)  // Add hey frame size
]

struct Player: View {
    let currentState: PlayerState
    let facingRight: Bool
    let walkFrame: Int  // Now received as prop instead of state
    
    var body: some View {
        let spriteName = currentSprite
        let size = frameSize[spriteName] ?? (60, 90)
        
        Image(spriteName)
            .resizable()
            .frame(width: size.0, height: size.1)
            .scaleEffect(x: facingRight ? 1 : -1, y: 1)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
            .animation(nil, value: spriteName)
            .contentTransition(.identity) // Disable any default cross-fade transition
    }
    
    private var currentSprite: String {
        switch currentState {
        case .idle:
            return "idle"
        case .walking:
            return "step-\(walkFrame)"
        case .jumping:
            return "jump"
        case .usingPhone:
            return "idle-phone"
        case .hey:
            return "hey"
        }
    }
}

#Preview {
    Player(currentState: .walking, facingRight: true, walkFrame: 0)
}

