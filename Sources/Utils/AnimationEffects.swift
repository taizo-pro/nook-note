import SwiftUI

// MARK: - Custom Transition Effects

extension AnyTransition {
    
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
    
    static var popIn: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.1).combined(with: .opacity),
            removal: .scale(scale: 0.1).combined(with: .opacity)
        )
    }
    
    static var slideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static func customSlide(edge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge).combined(with: .opacity)
        )
    }
}

// MARK: - Interactive Animation Modifiers

struct PressAnimation: ViewModifier {
    let scale: CGFloat
    let opacity: CGFloat
    
    init(scale: CGFloat = 0.95, opacity: CGFloat = 0.8) {
        self.scale = scale
        self.opacity = opacity
    }
    
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .opacity(isPressed ? opacity : 1.0)
            .animation(DesignSystem.Animation.fast, value: isPressed)
            .onTapGesture {
                withAnimation(DesignSystem.Animation.fast) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DesignSystem.Animation.fast) {
                        isPressed = false
                    }
                }
            }
    }
}

struct HoverAnimation: ViewModifier {
    let scale: CGFloat
    let rotation: Double
    let brightness: Double
    
    init(scale: CGFloat = 1.05, rotation: Double = 0, brightness: Double = 0.1) {
        self.scale = scale
        self.rotation = rotation
        self.brightness = brightness
    }
    
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .rotationEffect(.degrees(isHovered ? rotation : 0))
            .brightness(isHovered ? brightness : 0)
            .animation(DesignSystem.Animation.spring, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct ShakeEffect: ViewModifier {
    @State private var shakeOffset = 0.0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
    }
    
    func shake() {
        withAnimation(.easeInOut(duration: 0.05).repeatCount(6, autoreverses: true)) {
            shakeOffset = 5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeOffset = 0
        }
    }
}

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    
    init(minScale: CGFloat = 0.9, maxScale: CGFloat = 1.1, duration: Double = 1.0) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Loading Animations

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(DesignSystem.Colors.textSecondary)
                    .frame(width: 8, height: 8)
                    .opacity(animating ? 0.3 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, lineWidth: CGFloat = 4, size: CGFloat = 40) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.Colors.border, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DesignSystem.Colors.primary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animation.medium, value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct WaveAnimation: View {
    @State private var phase1 = 0.0
    @State private var phase2 = Double.pi / 3
    @State private var phase3 = 2 * Double.pi / 3
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Rectangle()
                .fill(DesignSystem.Colors.primary)
                .frame(width: 4, height: CGFloat(20 + 10 * sin(phase1)))
                .animation(
                    Animation.easeInOut(duration: 0.8).repeatForever(),
                    value: phase1
                )
            
            Rectangle()
                .fill(DesignSystem.Colors.primary)
                .frame(width: 4, height: CGFloat(20 + 10 * sin(phase2)))
                .animation(
                    Animation.easeInOut(duration: 0.8).repeatForever(),
                    value: phase2
                )
            
            Rectangle()
                .fill(DesignSystem.Colors.primary)
                .frame(width: 4, height: CGFloat(20 + 10 * sin(phase3)))
                .animation(
                    Animation.easeInOut(duration: 0.8).repeatForever(),
                    value: phase3
                )
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                phase1 += 0.3
                phase2 += 0.3
                phase3 += 0.3
            }
        }
    }
}

// MARK: - Notification Animations

struct NotificationSlideIn: ViewModifier {
    @State private var offset: CGFloat = -100
    let show: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: show ? 0 : offset)
            .opacity(show ? 1 : 0)
            .animation(DesignSystem.Animation.spring, value: show)
    }
}

struct SuccessCheckmark: View {
    @State private var strokeEnd: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 5, y: 15))
            path.addLine(to: CGPoint(x: 12, y: 22))
            path.addLine(to: CGPoint(x: 25, y: 8))
        }
        .trim(from: 0, to: strokeEnd)
        .stroke(DesignSystem.Colors.success, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .frame(width: 30, height: 30)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                strokeEnd = 1
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func pressAnimation(scale: CGFloat = 0.95, opacity: CGFloat = 0.8) -> some View {
        self.modifier(PressAnimation(scale: scale, opacity: opacity))
    }
    
    func hoverAnimation(scale: CGFloat = 1.05, rotation: Double = 0, brightness: Double = 0.1) -> some View {
        self.modifier(HoverAnimation(scale: scale, rotation: rotation, brightness: brightness))
    }
    
    func pulseEffect(minScale: CGFloat = 0.9, maxScale: CGFloat = 1.1, duration: Double = 1.0) -> some View {
        self.modifier(PulseEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    func notificationSlideIn(show: Bool) -> some View {
        self.modifier(NotificationSlideIn(show: show))
    }
    
    func shake() -> some View {
        self.modifier(ShakeEffect())
    }
    
    func animatedAppear(delay: Double = 0) -> some View {
        self
            .opacity(0)
            .scaleEffect(0.8)
            .onAppear {
                withAnimation(DesignSystem.Animation.spring.delay(delay)) {
                    // Animation will be applied by the state change
                }
            }
            .animation(DesignSystem.Animation.spring, value: true)
    }
    
    func bounceOnAppear() -> some View {
        self
            .scaleEffect(0.8)
            .opacity(0)
            .onAppear {
                withAnimation(DesignSystem.Animation.springBouncy) {
                    // Will animate to normal scale and opacity
                }
            }
    }
    
    func slideInFromEdge(_ edge: Edge, delay: Double = 0) -> some View {
        let offset: CGSize = {
            switch edge {
            case .top: return CGSize(width: 0, height: -50)
            case .bottom: return CGSize(width: 0, height: 50)
            case .leading: return CGSize(width: -50, height: 0)
            case .trailing: return CGSize(width: 50, height: 0)
            }
        }()
        
        return self
            .offset(offset)
            .opacity(0)
            .onAppear {
                withAnimation(DesignSystem.Animation.spring.delay(delay)) {
                    // Will animate to zero offset and full opacity
                }
            }
    }
}

// MARK: - Tab Animation Effects

struct TabSwitchAnimation: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isSelected ? 1.0 : 0.95)
            .opacity(isSelected ? 1.0 : 0.7)
            .animation(DesignSystem.Animation.medium, value: isSelected)
    }
}

extension View {
    func tabSwitchAnimation(isSelected: Bool) -> some View {
        self.modifier(TabSwitchAnimation(isSelected: isSelected))
    }
}