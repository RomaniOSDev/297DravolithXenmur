import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var storage: AppStorageService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Image("bannerCards")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 110)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [.clear, Color("AppBackground").opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .overlay(alignment: .bottomLeading) {
                            Text("Milestones")
                                .font(.title2.weight(.bold))
                                .foregroundColor(Color("AppTextPrimary"))
                                .padding(14)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: ThemeColor.primary.opacity(0.3), radius: 10, y: 5)
                        .padding(.horizontal, 16)

                    ForEach(AchievementCatalog.all) { item in
                        let unlocked = storage.isUnlocked(item.id)
                        let current = storage.stats.metricValue(for: item.metricKey)
                        let progress = min(Double(current) / Double(max(item.requiredValue, 1)), 1)

                        GoldElevatedCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            unlocked
                                            ? LinearGradient(colors: [ThemeColor.primary, ThemeColor.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [Color("AppBackground"), Color("AppBackground")], startPoint: .top, endPoint: .bottom)
                                        )
                                        .frame(width: 52, height: 52)
                                        .shadow(color: unlocked ? ThemeColor.primary.opacity(0.45) : .clear, radius: 8)
                                    Image(systemName: item.icon)
                                        .foregroundColor(unlocked ? Color("AppBackground") : Color("AppTextSecondary"))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundColor(Color("AppTextPrimary"))
                                        Spacer()
                                        if unlocked {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(ThemeColor.primary)
                                        }
                                    }
                                    Text(item.detail)
                                        .font(.caption)
                                        .foregroundColor(Color("AppTextSecondary"))
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color("AppBackground").opacity(0.6))
                                            Capsule()
                                                .fill(LinearGradient(colors: [ThemeColor.primary, ThemeColor.accent], startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geo.size.width * progress)
                                        }
                                    }
                                    .frame(height: 6)
                                    Text("\(min(current, item.requiredValue))/\(item.requiredValue)")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(Color("AppTextSecondary"))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(unlocked ? 1 : 0.85)
                    }
                }
                .padding(.bottom, 110)
            }
            .screenBackground()
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
