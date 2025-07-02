import SwiftUI
import AppKit

// MARK: - Responsive Design System

struct ResponsiveDesign {
    
    // MARK: - Window Sizes
    
    struct WindowSize {
        static let compact = CGSize(width: 320, height: 400)
        static let regular = CGSize(width: 400, height: 500)
        static let large = CGSize(width: 500, height: 600)
        static let xlarge = CGSize(width: 600, height: 700)
        
        // Dynamic sizing based on content
        static func adaptive(minWidth: CGFloat = 400, maxWidth: CGFloat = 600, 
                           minHeight: CGFloat = 500, maxHeight: CGFloat = 700) -> CGSize {
            return CGSize(width: min(max(minWidth, 400), maxWidth), 
                         height: min(max(minHeight, 500), maxHeight))
        }
    }
    
    // MARK: - Breakpoints
    
    enum Breakpoint: CaseIterable {
        case compact    // < 400 width
        case regular    // 400-500 width
        case large      // 500-600 width
        case xlarge     // > 600 width
        
        static func current(for size: CGSize) -> Breakpoint {
            switch size.width {
            case ..<400:
                return .compact
            case 400..<500:
                return .regular
            case 500..<600:
                return .large
            default:
                return .xlarge
            }
        }
        
        var maxContentWidth: CGFloat {
            switch self {
            case .compact: return 280
            case .regular: return 360
            case .large: return 460
            case .xlarge: return 560
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return DesignSystem.Spacing.sm
            case .regular: return DesignSystem.Spacing.md
            case .large: return DesignSystem.Spacing.lg
            case .xlarge: return DesignSystem.Spacing.xl
            }
        }
        
        var verticalSpacing: CGFloat {
            switch self {
            case .compact: return DesignSystem.Spacing.sm
            case .regular: return DesignSystem.Spacing.md
            case .large: return DesignSystem.Spacing.lg
            case .xlarge: return DesignSystem.Spacing.xl
            }
        }
    }
    
    // MARK: - Adaptive Components
    
    struct AdaptiveStack<Content: View>: View {
        let spacing: CGFloat?
        let content: Content
        @State private var currentSize: CGSize = .zero
        
        init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
            self.spacing = spacing
            self.content = content()
        }
        
        var body: some View {
            GeometryReader { geometry in
                let breakpoint = Breakpoint.current(for: geometry.size)
                let adaptiveSpacing = spacing ?? breakpoint.verticalSpacing
                
                if geometry.size.width < 400 {
                    VStack(spacing: adaptiveSpacing) {
                        content
                    }
                } else {
                    HStack(spacing: adaptiveSpacing) {
                        content
                    }
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            currentSize = geometry.size
                        }
                        .onChange(of: geometry.size) { newSize in
                            currentSize = newSize
                        }
                }
            )
        }
    }
    
    struct AdaptiveGrid<Content: View>: View {
        let columns: Int
        let spacing: CGFloat
        let content: Content
        
        init(columns: Int = 2, spacing: CGFloat = DesignSystem.Spacing.md, 
             @ViewBuilder content: () -> Content) {
            self.columns = columns
            self.spacing = spacing
            self.content = content()
        }
        
        var body: some View {
            GeometryReader { geometry in
                let breakpoint = Breakpoint.current(for: geometry.size)
                let adaptiveColumns = breakpoint == .compact ? 1 : columns
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: spacing), 
                                 count: adaptiveColumns),
                    spacing: spacing
                ) {
                    content
                }
            }
        }
    }
}

// MARK: - Adaptive Modifiers

struct AdaptivePadding: ViewModifier {
    let edges: Edge.Set
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let breakpoint = ResponsiveDesign.Breakpoint.current(for: geometry.size)
            
            content
                .padding(edges, breakpoint.horizontalPadding)
        }
    }
}

struct AdaptiveSpacing: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let breakpoint = ResponsiveDesign.Breakpoint.current(for: geometry.size)
            
            content
                .environment(\.screenSize, geometry.size)
        }
    }
}

struct AdaptiveFont: ViewModifier {
    let baseFont: Font
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let breakpoint = ResponsiveDesign.Breakpoint.current(for: geometry.size)
            let scaleFactor: CGFloat = {
                switch breakpoint {
                case .compact: return 0.9
                case .regular: return 1.0
                case .large: return 1.1
                case .xlarge: return 1.2
                }
            }()
            
            content
                .font(baseFont)
                .scaleEffect(scaleFactor)
        }
    }
}

// MARK: - Responsive Components

struct ResponsiveContainer<Content: View>: View {
    let content: Content
    let maxWidth: CGFloat?
    
    init(maxWidth: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let breakpoint = ResponsiveDesign.Breakpoint.current(for: geometry.size)
            let containerMaxWidth = maxWidth ?? breakpoint.maxContentWidth
            
            ScrollView {
                content
                    .frame(maxWidth: containerMaxWidth)
                    .padding(.horizontal, breakpoint.horizontalPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ResponsiveModal<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let breakpoint = ResponsiveDesign.Breakpoint.current(for: geometry.size)
            let modalSize: CGSize = {
                switch breakpoint {
                case .compact:
                    return ResponsiveDesign.WindowSize.compact
                case .regular:
                    return ResponsiveDesign.WindowSize.regular
                case .large:
                    return ResponsiveDesign.WindowSize.large
                case .xlarge:
                    return ResponsiveDesign.WindowSize.xlarge
                }
            }()
            
            ZStack {
                if isPresented {
                    // Backdrop
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(DesignSystem.Animation.medium) {
                                isPresented = false
                            }
                        }
                    
                    // Modal content
                    content
                        .frame(width: modalSize.width, height: modalSize.height)
                        .background(DesignSystem.Colors.background)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .shadow(color: DesignSystem.Shadow.large, radius: 20, x: 0, y: 10)
                        .scaleEffect(isPresented ? 1.0 : 0.8)
                        .opacity(isPresented ? 1.0 : 0.0)
                        .animation(DesignSystem.Animation.spring, value: isPresented)
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func adaptivePadding(_ edges: Edge.Set = .all) -> some View {
        self.modifier(AdaptivePadding(edges: edges))
    }
    
    func adaptiveSpacing() -> some View {
        self.modifier(AdaptiveSpacing())
    }
    
    func adaptiveFont(_ baseFont: Font) -> some View {
        self.modifier(AdaptiveFont(baseFont: baseFont))
    }
    
    func responsiveContainer(maxWidth: CGFloat? = nil) -> some View {
        ResponsiveContainer(maxWidth: maxWidth) {
            self
        }
    }
    
    func responsiveModal(isPresented: Binding<Bool>) -> some View {
        ResponsiveModal(isPresented: isPresented) {
            self
        }
    }
}

// MARK: - Screen Size Detection

struct ScreenSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = ResponsiveDesign.WindowSize.regular
}

extension EnvironmentValues {
    var screenSize: CGSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
}

struct ScreenSizeModifier: ViewModifier {
    @State private var screenSize: CGSize = ResponsiveDesign.WindowSize.regular
    
    func body(content: Content) -> some View {
        content
            .environment(\.screenSize, screenSize)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            screenSize = geometry.size
                        }
                        .onChange(of: geometry.size) { newSize in
                            screenSize = newSize
                        }
                }
            )
    }
}

extension View {
    func detectScreenSize() -> some View {
        self.modifier(ScreenSizeModifier())
    }
}

// MARK: - Accessibility Scaling

enum ContentSizeCategory: String, CaseIterable {
    case small, medium, large, extraLarge, extraExtraLarge, extraExtraExtraLarge
}

struct AccessibilityScaling {
    static func scaledFont(_ font: Font, for category: ContentSizeCategory = .large) -> Font {
        // SwiftUI handles accessibility scaling automatically on macOS
        return font
    }
    
    static func scaledSpacing(_ spacing: CGFloat, for category: ContentSizeCategory = .large) -> CGFloat {
        let scaleFactor: CGFloat = {
            switch category {
            case .small: return 0.9
            case .medium: return 0.95
            case .large: return 1.0
            case .extraLarge: return 1.1
            case .extraExtraLarge: return 1.2
            case .extraExtraExtraLarge: return 1.3
            }
        }()
        
        return spacing * scaleFactor
    }
}