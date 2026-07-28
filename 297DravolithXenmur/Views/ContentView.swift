import SwiftUI

struct ContentView: View {
    @StateObject private var storage = AppStorageService.shared
    @StateObject private var theme = ThemeManager.shared
    @State private var selectedTab: AppTab = .explore

    var body: some View {
        Group {
            if storage.hasSeenOnboarding {
                mainApp
            } else {
                OnboardingView()
            }
        }
        .environmentObject(storage)
        .environmentObject(theme)
        .preferredColorScheme(theme.preferredColorScheme)
        .id("\(theme.appearance.rawValue)-\(theme.accent.rawValue)")
    }

    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .explore:
                    CardExplorerView()
                case .study:
                    StudyHubView()
                case .achievements:
                    AchievementsView()
                case .settings:
                    SettingsView()
                }
            }

            FloatingTabBar(selection: $selectedTab)

            if let achievement = storage.newlyUnlockedAchievement {
                VStack {
                    AchievementBannerView(achievement: achievement) {
                        storage.clearAchievementBanner()
                    }
                    .padding(.top, 8)
                    Spacer()
                }
                .zIndex(2)
            }
        }
        .ignoresSafeArea(.keyboard)
        .dismissKeyboardOnTap()
    }
}
