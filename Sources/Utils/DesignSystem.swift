import SwiftUI
import AppKit

// MARK: - Design System

struct DesignSystem {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary Colors
        static let primary = Color.accentColor
        static let primaryHover = Color.accentColor.opacity(0.8)
        static let primaryPressed = Color.accentColor.opacity(0.6)
        
        // Background Colors
        static let background = Color(NSColor.windowBackgroundColor)
        static let surface = Color(NSColor.controlBackgroundColor)
        static let surfaceSecondary = Color(NSColor.controlBackgroundColor).opacity(0.5)
        static let surfaceHover = Color(NSColor.controlAccentColor).opacity(0.1)
        
        // Text Colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.secondary.opacity(0.6)
        static let textOnPrimary = Color.white
        
        // Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Border Colors
        static let border = Color.secondary.opacity(0.3)
        static let borderFocus = Color.accentColor.opacity(0.5)
        static let borderHover = Color.secondary.opacity(0.5)
        
        // GitHub Specific
        static let githubDiscussion = Color.blue
        static let githubComment = Color.gray
        static let githubAuthor = Color.accentColor
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Headlines
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        
        // Body Text
        static let bodyLarge = Font.body.weight(.regular)
        static let body = Font.system(size: 13, weight: .regular)
        static let bodySmall = Font.system(size: 12, weight: .regular)
        
        // UI Elements
        static let buttonLabel = Font.system(size: 13, weight: .medium)
        static let caption = Font.caption.weight(.regular)
        static let captionBold = Font.caption.weight(.semibold)
        
        // Code/Monospace
        static let code = Font.system(.body, design: .monospaced)
        static let codeSmall = Font.system(size: 12, design: .monospaced)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
    }
    
    // MARK: - Shadow
    
    struct Shadow {
        static let small = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.15)
        static let large = Color.black.opacity(0.2)
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
        
        // Spring animations
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
    }
}

// MARK: - Custom View Modifiers

struct PrimaryButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.buttonLabel)
            .foregroundColor(DesignSystem.Colors.textOnPrimary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(backgroundColor(for: configuration))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        let baseColor = isDestructive ? DesignSystem.Colors.error : DesignSystem.Colors.primary
        
        if configuration.isPressed {
            return baseColor.opacity(0.8)
        } else {
            return baseColor
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.buttonLabel)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

struct CardStyle: ViewModifier {
    let padding: CGFloat
    let isInteractive: Bool
    
    init(padding: CGFloat = DesignSystem.Spacing.lg, isInteractive: Bool = false) {
        self.padding = padding
        self.isInteractive = isInteractive
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.surface)
                    .shadow(color: DesignSystem.Shadow.small, radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
            )
    }
}

struct InteractiveCardStyle: ViewModifier {
    @State private var isHovered = false
    let onTap: (() -> Void)?
    
    init(onTap: (() -> Void)? = nil) {
        self.onTap = onTap
    }
    
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isHovered ? DesignSystem.Colors.surfaceHover : DesignSystem.Colors.surface)
                    .shadow(color: isHovered ? DesignSystem.Shadow.medium : DesignSystem.Shadow.small, 
                           radius: isHovered ? 4 : 2, x: 0, y: isHovered ? 2 : 1)
                    .animation(DesignSystem.Animation.fast, value: isHovered)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isHovered ? DesignSystem.Colors.borderHover : DesignSystem.Colors.border, lineWidth: 0.5)
                    .animation(DesignSystem.Animation.fast, value: isHovered)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.Animation.spring, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                onTap?()
            }
    }
}

struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isLoading {
                        ZStack {
                            Rectangle()
                                .fill(DesignSystem.Colors.background.opacity(0.8))
                            
                            VStack(spacing: DesignSystem.Spacing.md) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                
                                Text(message)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            .padding(DesignSystem.Spacing.xl)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .fill(DesignSystem.Colors.surface)
                                    .shadow(color: DesignSystem.Shadow.large, radius: 8, x: 0, y: 4)
                            )
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(DesignSystem.Animation.medium, value: isLoading)
                    }
                }
            )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.lg, isInteractive: Bool = false) -> some View {
        self.modifier(CardStyle(padding: padding, isInteractive: isInteractive))
    }
    
    func interactiveCardStyle(onTap: (() -> Void)? = nil) -> some View {
        self.modifier(InteractiveCardStyle(onTap: onTap))
    }
    
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
    
    func primaryButtonStyle(isDestructive: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isDestructive: isDestructive))
    }
    
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}

// MARK: - Status Badge Component

struct StatusBadge: View {
    let text: String
    let style: StatusStyle
    
    enum StatusStyle {
        case success, warning, error, info, neutral
        
        var color: Color {
            switch self {
            case .success: return DesignSystem.Colors.success
            case .warning: return DesignSystem.Colors.warning
            case .error: return DesignSystem.Colors.error
            case .info: return DesignSystem.Colors.info
            case .neutral: return DesignSystem.Colors.textSecondary
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                    .fill(style.color)
            )
    }
}

// MARK: - Feedback Components

struct FeedbackBanner: View {
    let message: String
    let type: FeedbackType
    let onDismiss: (() -> Void)?
    
    enum FeedbackType {
        case success, warning, error, info
        
        var color: Color {
            switch self {
            case .success: return DesignSystem.Colors.success
            case .warning: return DesignSystem.Colors.warning
            case .error: return DesignSystem.Colors.error
            case .info: return DesignSystem.Colors.info
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}