import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case explore
    case study
    case achievements
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .explore: return "Explore"
        case .study: return "Study"
        case .achievements: return "Awards"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .explore: return "rectangle.stack.fill"
        case .study: return "lightbulb.fill"
        case .achievements: return "trophy.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    HapticFeedback.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: selection == tab ? 18 : 16, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(selection == tab ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [ThemeColor.primary, ThemeColor.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: ThemeColor.primary.opacity(0.55), radius: 8, y: 3)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            Capsule(style: .continuous)
                .fill(Color("AppSurface"))
                .shadow(color: ThemeColor.primary.opacity(0.28), radius: 16, y: 8)
                .shadow(color: .black.opacity(0.45), radius: 12, y: 6)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(ThemeColor.primary.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }
}

struct AchievementBannerView: View {
    let achievement: AchievementDefinition
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(Color("AppBackground"))
                .padding(10)
                .background(Circle().fill(ThemeColor.primary))
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(ThemeColor.accent)
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color("AppTextPrimary"))
            }
            Spacer()
            Button {
                HapticFeedback.light()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(Color("AppTextSecondary"))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color("AppSurface"))
                .shadow(color: ThemeColor.primary.opacity(0.5), radius: 14, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ThemeColor.primary.opacity(0.6), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                onDismiss()
            }
        }
    }
}
