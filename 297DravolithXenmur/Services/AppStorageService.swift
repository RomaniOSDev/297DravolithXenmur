import Foundation
import Combine

final class AppStorageService: ObservableObject {
    static let shared = AppStorageService()

    @Published var flashcards: [Flashcard] = []
    @Published var quizzes: [Quiz] = []
    @Published var quizResults: [QuizResult] = []
    @Published var stats: StudyStats = .empty
    @Published var hasSeenOnboarding: Bool = false
    @Published var newlyUnlockedAchievement: AchievementDefinition?

    private let cardsKey = "clarity_flashcards"
    private let quizzesKey = "clarity_quizzes"
    private let resultsKey = "clarity_quiz_results"
    private let statsKey = "clarity_stats"
    private let onboardingKey = "clarity_hasSeenOnboarding"
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private init() {
        load()
        refreshTodayCounterIfNeeded()
    }

    // MARK: - Persistence

    private func load() {
        flashcards = decode([Flashcard].self, key: cardsKey) ?? []
        quizzes = decode([Quiz].self, key: quizzesKey) ?? []
        quizResults = decode([QuizResult].self, key: resultsKey) ?? []
        stats = decode(StudyStats.self, key: statsKey) ?? .empty
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
    }

    private func persistCards() {
        encode(flashcards, key: cardsKey)
    }

    private func persistQuizzes() {
        encode(quizzes, key: quizzesKey)
    }

    private func persistResults() {
        encode(quizResults, key: resultsKey)
    }

    private func persistStats() {
        encode(stats, key: statsKey)
        evaluateAchievements()
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
    }

    // MARK: - Flashcards

    var topics: [String] {
        Array(Set(flashcards.map(\.topic))).sorted()
    }

    var allTags: [String] {
        Array(Set(flashcards.flatMap(\.tags))).sorted()
    }

    func cards(for topic: String) -> [Flashcard] {
        flashcards.filter { $0.topic == topic }
    }

    func dueCards() -> [Flashcard] {
        flashcards.filter(\.isDue).sorted {
            ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast)
        }
    }

    func wrongAnswerCards() -> [Flashcard] {
        let ids = Set(stats.wrongAnswerCardIds)
        return flashcards.filter { ids.contains($0.id) }
    }

    func addCards(_ cards: [Flashcard]) {
        flashcards.append(contentsOf: cards)
        persistCards()
        refreshTopicsCompleted()
        objectWillChange.send()
    }

    func updateCardStatus(id: UUID, status: CardStatus) {
        guard let index = flashcards.firstIndex(where: { $0.id == id }) else { return }
        flashcards[index].status = status
        if status == .known {
            flashcards[index].nextReviewDate = calendar.date(byAdding: .day, value: 7, to: Date())
            flashcards[index].intervalDays = max(flashcards[index].intervalDays, 7)
        } else if status == .learning {
            flashcards[index].nextReviewDate = Date()
            flashcards[index].intervalDays = 1
        }
        persistCards()
        recordCardReview(minutes: 1)
        refreshTopicsCompleted()
    }

    func reviewWithSM2(id: UUID, quality: ReviewQuality) {
        guard let index = flashcards.firstIndex(where: { $0.id == id }) else { return }
        SM2Engine.apply(quality: quality, to: &flashcards[index])
        persistCards()
        recordCardReview(minutes: 1)
        refreshTopicsCompleted()
    }

    func deleteCard(id: UUID) {
        flashcards.removeAll { $0.id == id }
        stats.wrongAnswerCardIds.removeAll { $0 == id }
        persistCards()
        persistStats()
        refreshTopicsCompleted()
    }

    // MARK: - Quizzes

    func createQuiz(title: String, topic: String, count: Int, mode: QuizMode = .multipleChoice) -> Quiz? {
        let pool = flashcards.filter { $0.topic == topic }
        guard !pool.isEmpty else { return nil }
        let selected = Array(pool.shuffled().prefix(max(1, min(count, pool.count))))
        let quiz = Quiz(title: title, topic: topic, cardIds: selected.map(\.id), mode: mode)
        quizzes.insert(quiz, at: 0)
        persistQuizzes()
        return quiz
    }

    func createWrongAnswersQuiz() -> Quiz? {
        let cards = wrongAnswerCards()
        guard !cards.isEmpty else { return nil }
        let quiz = Quiz(
            title: "Review Mistakes",
            topic: "Mistakes",
            cardIds: cards.map(\.id),
            mode: .multipleChoice
        )
        quizzes.insert(quiz, at: 0)
        persistQuizzes()
        return quiz
    }

    func questions(for quiz: Quiz) -> [QuizQuestion] {
        let cards = quiz.cardIds.compactMap { id in flashcards.first(where: { $0.id == id }) }
        let allBacks = flashcards.map(\.back)
        return cards.map { card in
            switch quiz.mode {
            case .multipleChoice:
                var options = Set<String>([card.back])
                let distractors = allBacks.filter { $0 != card.back }.shuffled()
                for d in distractors where options.count < 4 {
                    options.insert(d)
                }
                return QuizQuestion(
                    id: card.id,
                    card: card,
                    options: Array(options).shuffled(),
                    correctAnswer: card.back,
                    mode: .multipleChoice,
                    statementIsTrue: true,
                    prompt: card.front
                )
            case .trueFalse:
                let isTrue = Bool.random()
                let shownAnswer: String
                if isTrue {
                    shownAnswer = card.back
                } else {
                    let others = allBacks.filter { $0 != card.back }
                    shownAnswer = others.randomElement() ?? "Not \(card.back)"
                }
                return QuizQuestion(
                    id: card.id,
                    card: card,
                    options: ["True", "False"],
                    correctAnswer: isTrue ? "True" : "False",
                    mode: .trueFalse,
                    statementIsTrue: isTrue,
                    prompt: "Q: \(card.front)\nA: \(shownAnswer)"
                )
            case .typed:
                return QuizQuestion(
                    id: card.id,
                    card: card,
                    options: [],
                    correctAnswer: card.back,
                    mode: .typed,
                    statementIsTrue: true,
                    prompt: card.front
                )
            }
        }
    }

    func answersMatch(_ typed: String, correct: String) -> Bool {
        let a = typed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let b = correct.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !a.isEmpty && a == b
    }

    func submitQuiz(quiz: Quiz, score: Int, total: Int, missedCardIds: [UUID] = []) {
        let result = QuizResult(
            quizId: quiz.id,
            quizTitle: quiz.title,
            score: score,
            total: total,
            missedCardIds: missedCardIds,
            mode: quiz.mode
        )
        quizResults.insert(result, at: 0)
        persistResults()
        stats.quizzesCompleted += 1

        var wrong = Set(stats.wrongAnswerCardIds)
        for id in missedCardIds { wrong.insert(id) }
        let correctIds = Set(quiz.cardIds).subtracting(missedCardIds)
        wrong.subtract(correctIds)
        stats.wrongAnswerCardIds = Array(wrong)

        recordStudyActivity(minutes: max(2, total))
        persistStats()
    }

    // MARK: - Goals / Focus

    var dailyGoalProgress: Double {
        refreshTodayCounterIfNeeded()
        guard stats.dailyGoalCards > 0 else { return 0 }
        return min(Double(stats.cardsReviewedToday) / Double(stats.dailyGoalCards), 1)
    }

    func updateDailyGoal(_ value: Int) {
        stats.dailyGoalCards = max(1, min(value, 200))
        persistStats()
    }

    func updateReminder(enabled: Bool, hour: Int? = nil, minute: Int? = nil) {
        stats.remindersEnabled = enabled
        if let hour { stats.reminderHour = hour }
        if let minute { stats.reminderMinute = minute }
        persistStats()
        NotificationService.scheduleDailyReminder(
            hour: stats.reminderHour,
            minute: stats.reminderMinute,
            enabled: enabled
        )
    }

    func recordFocusSession(minutes: Int) {
        stats.focusSessionsCompleted += 1
        recordStudyActivity(minutes: max(1, minutes))
        persistStats()
    }

    // MARK: - Dashboard / Stats

    func topicProgressList() -> [TopicProgress] {
        topics.map { topic in
            let cards = cards(for: topic)
            let known = cards.filter { $0.status == .known }.count
            return TopicProgress(
                topic: topic,
                knownCount: known,
                totalCount: cards.count,
                isBookmarked: stats.bookmarkedTopics.contains(topic)
            )
        }
    }

    func toggleBookmark(topic: String) {
        if let idx = stats.bookmarkedTopics.firstIndex(of: topic) {
            stats.bookmarkedTopics.remove(at: idx)
        } else {
            stats.bookmarkedTopics.append(topic)
        }
        persistStats()
    }

    func activityCounts(for range: DashboardRange) -> [(label: String, value: Int)] {
        let today = calendar.startOfDay(for: Date())
        switch range {
        case .daily:
            return (0..<7).reversed().map { offset -> (String, Int) in
                let date = calendar.date(byAdding: .day, value: -offset, to: today)!
                let key = dayFormatter.string(from: date)
                let label = shortDay(date)
                return (label, stats.activityByDay[key] ?? 0)
            }
        case .weekly:
            return (0..<4).reversed().map { offset -> (String, Int) in
                let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: today)!
                let end = calendar.date(byAdding: .day, value: 6, to: start)!
                var total = 0
                var d = start
                while d <= end {
                    total += stats.activityByDay[dayFormatter.string(from: d)] ?? 0
                    d = calendar.date(byAdding: .day, value: 1, to: d)!
                }
                return ("W\(4 - offset)", total)
            }
        case .monthly:
            return (0..<6).reversed().map { offset -> (String, Int) in
                let date = calendar.date(byAdding: .month, value: -offset, to: today)!
                let comps = calendar.dateComponents([.year, .month], from: date)
                var total = 0
                for (key, value) in stats.activityByDay {
                    guard let parsed = dayFormatter.date(from: key) else { continue }
                    let pc = calendar.dateComponents([.year, .month], from: parsed)
                    if pc.year == comps.year && pc.month == comps.month {
                        total += value
                    }
                }
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return (formatter.string(from: date), total)
            }
        }
    }

    func quizAccuracySeries(limit: Int = 8) -> [(label: String, value: Int)] {
        let recent = Array(quizResults.prefix(limit).reversed())
        return recent.enumerated().map { index, result in
            let label = recent.count <= 4 ? String(result.quizTitle.prefix(8)) : "#\(index + 1)"
            return (label, result.percentage)
        }
    }

    func cardStatusBreakdown() -> [(label: String, value: Int, color: String)] {
        let known = flashcards.filter { $0.status == .known }.count
        let learning = flashcards.filter { $0.status == .learning }.count
        let fresh = flashcards.filter { $0.status == .new }.count
        return [
            ("Known", known, "AppPrimary"),
            ("Learning", learning, "AppAccent"),
            ("New", fresh, "AppTextSecondary")
        ]
    }

    // MARK: - Achievements

    func isUnlocked(_ id: String) -> Bool {
        stats.unlockedAchievementIds.contains(id)
    }

    private func evaluateAchievements() {
        for def in AchievementCatalog.all {
            guard !stats.unlockedAchievementIds.contains(def.id) else { continue }
            if stats.metricValue(for: def.metricKey) >= def.requiredValue {
                stats.unlockedAchievementIds.append(def.id)
                encode(stats, key: statsKey)
                newlyUnlockedAchievement = def
                SoundPlayer.playSuccess()
                HapticFeedback.success()
            }
        }
    }

    func clearAchievementBanner() {
        newlyUnlockedAchievement = nil
    }

    // MARK: - Reset

    func resetAllData() {
        flashcards = []
        quizzes = []
        quizResults = []
        stats = .empty
        persistCards()
        persistQuizzes()
        persistResults()
        persistStats()
        newlyUnlockedAchievement = nil
        NotificationService.scheduleDailyReminder(hour: 19, minute: 0, enabled: false)
    }

    // MARK: - Internal helpers

    private func recordCardReview(minutes: Int) {
        stats.cardsReviewed += 1
        refreshTodayCounterIfNeeded()
        stats.cardsReviewedToday += 1
        recordStudyActivity(minutes: minutes)
        persistStats()
    }

    private func recordStudyActivity(minutes: Int) {
        stats.studyMinutes += minutes
        let key = dayFormatter.string(from: Date())
        stats.activityByDay[key, default: 0] += 1
        updateStreak()
    }

    private func refreshTodayCounterIfNeeded() {
        let key = dayFormatter.string(from: Date())
        if stats.cardsReviewedTodayKey != key {
            stats.cardsReviewedTodayKey = key
            stats.cardsReviewedToday = 0
        }
    }

    private func updateStreak() {
        let today = calendar.startOfDay(for: Date())
        if let last = stats.lastStudyDate {
            let lastDay = calendar.startOfDay(for: last)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 {
                // same day
            } else if diff == 1 {
                stats.streakDays += 1
            } else {
                stats.streakDays = 1
            }
        } else {
            stats.streakDays = 1
        }
        stats.lastStudyDate = Date()
    }

    private func refreshTopicsCompleted() {
        let completed = topicProgressList().filter(\.isComplete).count
        if completed != stats.topicsCompleted {
            stats.topicsCompleted = completed
            persistStats()
        }
    }

    private func shortDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
}

enum DashboardRange: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    var id: String { rawValue }
}
