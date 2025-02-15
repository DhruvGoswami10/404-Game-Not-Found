import SwiftUI

struct ControlButton: View {
    let iconName: String
    let onTouchBegan: () -> Void
    let onTouchEnded: () -> Void
    let size: CGFloat
    let opacity: Double
    @GestureState private var isPressed = false
    
    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .frame(width: size, height: size)
            .foregroundColor(.blue)
            .opacity(isPressed ? 0.5 : opacity)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
                    .onChanged { _ in
                        onTouchBegan()
                    }
                    .onEnded { _ in
                        onTouchEnded()
                    }
            )
    }
}

struct ControlConfig {
    let size: CGFloat
    let position: CGPoint
    let opacity: Double
}

struct Controls: View {
    let leftConfig: ControlConfig
    let jumpConfig: ControlConfig
    let rightConfig: ControlConfig
    let onLeftBegan: () -> Void
    let onLeftEnded: () -> Void
    let onRightBegan: () -> Void
    let onRightEnded: () -> Void
    let onJumpBegan: () -> Void
    let onJumpEnded: () -> Void
    
    var body: some View {
        ZStack {
            // Left control
            ControlButton(
                iconName: "l.joystick.tilt.left",
                onTouchBegan: onLeftBegan,
                onTouchEnded: onLeftEnded,
                size: leftConfig.size,
                opacity: leftConfig.opacity
            )
            .position(leftConfig.position)
            
            // Jump control
            ControlButton(
                iconName: "arrowtriangle.up.circle.fill",
                onTouchBegan: onJumpBegan,
                onTouchEnded: onJumpEnded,
                size: jumpConfig.size,
                opacity: jumpConfig.opacity
            )
            .position(jumpConfig.position)
            
            // Right control
            ControlButton(
                iconName: "r.joystick.tilt.right.fill",
                onTouchBegan: onRightBegan,
                onTouchEnded: onRightEnded,
                size: rightConfig.size,
                opacity: rightConfig.opacity
            )
            .position(rightConfig.position)
        }
    }
}

#Preview {
    Controls(
        leftConfig: ControlConfig(size: 50, position: CGPoint(x: 100, y: 200), opacity: 0.7),
        jumpConfig: ControlConfig(size: 60, position: CGPoint(x: 200, y: 200), opacity: 0.7),
        rightConfig: ControlConfig(size: 50, position: CGPoint(x: 300, y: 200), opacity: 0.7),
        onLeftBegan: {},
        onLeftEnded: {},
        onRightBegan: {},
        onRightEnded: {},
        onJumpBegan: {},
        onJumpEnded: {}
    )
}
