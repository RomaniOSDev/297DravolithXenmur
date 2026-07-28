import SwiftUI

struct StudyDashboardView: View {
    @EnvironmentObject private var storage: AppStorageService
    @State private var range: DashboardRange = .daily
    @State private var showAnalyze = false

    private var progress: [TopicProgress] {
        storage.topicProgressList()
    }

    private var hasData: Bool {
        !storage.flashcards.isEmpty || storage.stats.cardsReviewed > 0
    }

    private var accuracyItems: [(label: String, value: Int)] {
        storage.quizAccuracySeries()
    }

    private var statusItems: [(label: String, value: Int, color: String)] {
        storage.cardStatusBreakdown()
    }

    var body: some View {
        Group {
            if !hasData {
                VStack {
                    Spacer()
                    EmptyStateView(
                        title: "Track your learning journey here!",
                        systemImage: "chart.pie.fill"
                    )
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        statsHeader

                        Picker("Range", selection: $range) {
                            ForEach(DashboardRange.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        GoldElevatedCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Activity")
                                    .font(.headline)
                                    .foregroundColor(Color("AppTextPrimary"))
                                ActivityBarChart(items: storage.activityCounts(for: range))
                            }
                        }
                        .padding(.horizontal, 16)

                        GoldElevatedCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quiz Accuracy")
                                    .font(.headline)
                                    .foregroundColor(Color("AppTextPrimary"))
                                if accuracyItems.isEmpty {
                                    Text("Complete quizzes to see your score trend.")
                                        .font(.caption)
                                        .foregroundColor(Color("AppTextSecondary"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 24)
                                } else {
                                    LineChartView(items: accuracyItems, unitSuffix: "%")
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        GoldElevatedCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Card Status")
                                    .font(.headline)
                                    .foregroundColor(Color("AppTextPrimary"))
                                StatusDistributionChart(items: statusItems)
                            }
                        }
                        .padding(.horizontal, 16)

                        HStack {
                            Text("Topic Progress")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            Spacer()
                            Button {
                                HapticFeedback.light()
                                showAnalyze = true
                            } label: {
                                Label("Full Stats", systemImage: "chart.xyaxis.line")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(ThemeColor.primary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        if progress.isEmpty {
                            EmptyStateView(
                                title: "Track your learning journey here!",
                                systemImage: "chart.pie.fill"
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(progress) { item in
                                        GoldElevatedCard(padding: 12) {
                                            VStack(spacing: 10) {
                                                ProgressRingView(
                                                    progress: item.ratio,
                                                    label: item.topic,
                                                    detail: "\(item.knownCount)/\(item.totalCount)"
                                                )
                                                Button {
                                                    HapticFeedback.light()
                                                    storage.toggleBookmark(topic: item.topic)
                                                } label: {
                                                    Image(systemName: item.isBookmarked ? "bookmark.fill" : "bookmark")
                                                        .foregroundColor(ThemeColor.primary)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        .frame(width: 140)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            ForEach(progress) { item in
                                GoldElevatedCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.topic)
                                                .font(.headline)
                                                .foregroundColor(Color("AppTextPrimary"))
                                            Text("\(item.knownCount) of \(item.totalCount) known")
                                                .font(.caption)
                                                .foregroundColor(Color("AppTextSecondary"))
                                        }
                                        Spacer()
                                        Button {
                                            HapticFeedback.light()
                                            storage.toggleBookmark(topic: item.topic)
                                        } label: {
                                            Image(systemName: item.isBookmarked ? "bookmark.fill" : "bookmark")
                                                .foregroundColor(ThemeColor.primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        GoldElevatedCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Daily goal")
                                    .font(.headline)
                                    .foregroundColor(Color("AppTextPrimary"))
                                ProgressView(value: storage.dailyGoalProgress)
                                    .tint(ThemeColor.primary)
                                Text("\(storage.stats.cardsReviewedToday) / \(storage.stats.dailyGoalCards) cards · \(storage.dueCards().count) due for review")
                                    .font(.caption)
                                    .foregroundColor(Color("AppTextSecondary"))
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 110)
                }
            }
        }
        .sheet(isPresented: $showAnalyze) {
            AnalyzeProgressView()
                .environmentObject(storage)
        }
    }

    private var statsHeader: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            miniStat("Streak", "\(storage.stats.streakDays)d", "flame.fill")
            miniStat("Minutes", "\(storage.stats.studyMinutes)", "clock.fill")
            miniStat("Quizzes", "\(storage.stats.quizzesCompleted)", "checkmark.circle.fill")
        }
        .padding(.horizontal, 16)
    }

    private func miniStat(_ title: String, _ value: String, _ icon: String) -> some View {
        GoldElevatedCard(padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(ThemeColor.primary)
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundColor(Color("AppTextPrimary"))
                Text(title)
                    .font(.caption2)
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
    }
}

struct AnalyzeProgressView: View {
    @EnvironmentObject private var storage: AppStorageService
    @Environment(\.dismiss) private var dismiss
    @State private var range: DashboardRange = .daily

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    let stats = storage.stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statTile("Cards Reviewed", "\(stats.cardsReviewed)", "rectangle.stack")
                        statTile("Quizzes", "\(stats.quizzesCompleted)", "checkmark.circle")
                        statTile("Topics Done", "\(stats.topicsCompleted)", "map")
                        statTile("Streak", "\(stats.streakDays)d", "flame")
                        statTile("Minutes", "\(stats.studyMinutes)", "clock")
                        statTile("Bookmarks", "\(stats.bookmarkedTopics.count)", "bookmark")
                    }
                    .padding(.horizontal, 16)

                    Picker("Range", selection: $range) {
                        ForEach(DashboardRange.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Study Activity")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            ActivityBarChart(items: storage.activityCounts(for: range))
                        }
                    }
                    .padding(.horizontal, 16)

                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quiz Accuracy")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            let accuracy = storage.quizAccuracySeries(limit: 10)
                            if accuracy.isEmpty {
                                Text("No quiz results yet.")
                                    .font(.caption)
                                    .foregroundColor(Color("AppTextSecondary"))
                                    .padding(.vertical, 20)
                            } else {
                                LineChartView(items: accuracy, unitSuffix: "%")
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mastery Mix")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            StatusDistributionChart(items: storage.cardStatusBreakdown())
                        }
                    }
                    .padding(.horizontal, 16)

                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Insight")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            Text(insightText)
                                .font(.subheadline)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .screenBackground()
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.light()
                        dismiss()
                    }
                    .foregroundColor(ThemeColor.primary)
                }
            }
        }
    }

    private var insightText: String {
        let stats = storage.stats
        if stats.cardsReviewed == 0 {
            return "Start reviewing flashcards to unlock personalized insights."
        }
        if stats.streakDays >= 7 {
            return "Excellent consistency! Your streak shows strong study habits."
        }
        if stats.quizzesCompleted > 0 {
            return "Keep mixing quizzes with card reviews to reinforce retention."
        }
        return "You're building momentum — mark cards as known to complete topics."
    }

    private func statTile(_ title: String, _ value: String, _ icon: String) -> some View {
        GoldElevatedCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(ThemeColor.primary)
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color("AppTextPrimary"))
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
    }
}
