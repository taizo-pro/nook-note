import SwiftUI

// MARK: - Skeleton Loading Components

struct SkeletonView: View {
    @State private var isAnimating = false
    let cornerRadius: CGFloat
    let height: CGFloat?
    
    init(cornerRadius: CGFloat = DesignSystem.CornerRadius.sm, height: CGFloat? = nil) {
        self.cornerRadius = cornerRadius
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.surface,
                        DesignSystem.Colors.surface.opacity(0.6),
                        DesignSystem.Colors.surface
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(cornerRadius)
            .frame(height: height)
            .opacity(isAnimating ? 0.3 : 0.8)
            .animation(
                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct SkeletonDiscussionRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header skeleton
            HStack {
                SkeletonView(height: 20)
                    .frame(width: 40)
                
                SkeletonView(height: 20)
                    .frame(width: 80)
                
                Spacer()
                
                SkeletonView(height: 16)
                    .frame(width: 60)
            }
            
            // Title skeleton
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                SkeletonView(height: 18)
                    .frame(maxWidth: .infinity)
                
                SkeletonView(height: 18)
                    .frame(width: 200)
            }
            
            // Body skeleton
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                SkeletonView(height: 14)
                    .frame(maxWidth: .infinity)
                
                SkeletonView(height: 14)
                    .frame(width: 150)
            }
            
            // Footer skeleton
            HStack {
                SkeletonView(height: 14)
                    .frame(width: 80)
                
                Spacer()
                
                SkeletonView(height: 14)
                    .frame(width: 30)
            }
        }
        .cardStyle()
    }
}

struct SkeletonCommentRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                SkeletonView(height: 14)
                    .frame(width: 70)
                
                Spacer()
                
                SkeletonView(height: 12)
                    .frame(width: 50)
            }
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                SkeletonView(height: 16)
                    .frame(maxWidth: .infinity)
                
                SkeletonView(height: 16)
                    .frame(maxWidth: .infinity)
                
                SkeletonView(height: 16)
                    .frame(width: 180)
            }
        }
        .cardStyle(padding: DesignSystem.Spacing.md)
    }
}

// MARK: - Loading States

struct LoadingStateView: View {
    let message: String
    let showProgress: Bool
    
    init(message: String = "Loading...", showProgress: Bool = true) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(DesignSystem.Colors.primary)
            }
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .primaryButtonStyle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(title: String = "Something went wrong", message: String, retryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.warning)
            
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .primaryButtonStyle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Advanced Loading Indicators

struct PulsingDots: View {
    @State private var animating = false
    let dotCount = 3
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.3)
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

struct CircularProgressView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    
    init(progress: Double, lineWidth: CGFloat = 4) {
        self.progress = progress
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(DesignSystem.Colors.border, lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DesignSystem.Colors.primary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animation.medium, value: progress)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Loading List Views

struct LoadingDiscussionsList: View {
    let itemCount: Int
    
    init(itemCount: Int = 5) {
        self.itemCount = itemCount
    }
    
    var body: some View {
        LazyVStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<itemCount, id: \.self) { _ in
                SkeletonDiscussionRow()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.sm)
    }
}

struct LoadingCommentsList: View {
    let itemCount: Int
    
    init(itemCount: Int = 3) {
        self.itemCount = itemCount
    }
    
    var body: some View {
        LazyVStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<itemCount, id: \.self) { _ in
                SkeletonCommentRow()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

// MARK: - View Extensions

extension View {
    func withLoadingState<Loading: View, ErrorView: View, Empty: View>(
        isLoading: Bool,
        errorMessage: String? = nil,
        isEmpty: Bool = false,
        @ViewBuilder loading: () -> Loading,
        @ViewBuilder errorView: (String) -> ErrorView,
        @ViewBuilder empty: () -> Empty
    ) -> some View {
        ZStack {
            if isLoading {
                loading()
                    .transition(.opacity)
            } else if let error = errorMessage {
                errorView(error)
                    .transition(.opacity)
            } else if isEmpty {
                empty()
                    .transition(.opacity)
            } else {
                self
                    .transition(.opacity)
            }
        }
        .animation(DesignSystem.Animation.medium, value: isLoading)
        .animation(DesignSystem.Animation.medium, value: errorMessage)
        .animation(DesignSystem.Animation.medium, value: isEmpty)
    }
    
    func skeletonLoading(_ isLoading: Bool) -> some View {
        self.redacted(reason: isLoading ? .placeholder : [])
    }
}