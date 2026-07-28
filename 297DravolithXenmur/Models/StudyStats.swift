import Foundation

struct TopicProgress: Codable, Equatable, Identifiable {
    var id: String { topic }
    var topic: String
    var knownCount: Int
    var totalCount: Int
    var isBookmarked: Bool

    var ratio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(knownCount) / Double(totalCount)
    }

    var isComplete: Bool {
        totalCount > 0 && knownCount >= totalCount
    }
}

struct StudyStats: Codable, Equatable {
    var cardsReviewed: Int
    var quizzesCompleted: Int
    var topicsCompleted: Int
    var streakDays: Int
    var studyMinutes: Int
    var lastStudyDate: Date?
    var bookmarkedTopics: [String]
    var activityByDay: [String: Int]
    var unlockedAchievementIds: [String]
    var dailyGoalCards: Int
    var remindersEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var focusSessionsCompleted: Int
    var wrongAnswerCardIds: [UUID]
    var cardsReviewedToday: Int
    var cardsReviewedTodayKey: String

    static let empty = StudyStats(
        cardsReviewed: 0,
        quizzesCompleted: 0,
        topicsCompleted: 0,
        streakDays: 0,
        studyMinutes: 0,
        lastStudyDate: nil,
        bookmarkedTopics: [],
        activityByDay: [:],
        unlockedAchievementIds: [],
        dailyGoalCards: 20,
        remindersEnabled: false,
        reminderHour: 19,
        reminderMinute: 0,
        focusSessionsCompleted: 0,
        wrongAnswerCardIds: [],
        cardsReviewedToday: 0,
        cardsReviewedTodayKey: ""
    )

    func metricValue(for key: String) -> Int {
        switch key {
        case "cardsReviewed": return cardsReviewed
        case "quizzesCompleted": return quizzesCompleted
        case "topicsCompleted": return topicsCompleted
        case "streakDays": return streakDays
        case "studyMinutes": return studyMinutes
        default: return 0
        }
    }

    enum CodingKeys: String, CodingKey {
        case cardsReviewed, quizzesCompleted, topicsCompleted, streakDays, studyMinutes
        case lastStudyDate, bookmarkedTopics, activityByDay, unlockedAchievementIds
        case dailyGoalCards, remindersEnabled, reminderHour, reminderMinute
        case focusSessionsCompleted, wrongAnswerCardIds, cardsReviewedToday, cardsReviewedTodayKey
    }

    init(
        cardsReviewed: Int,
        quizzesCompleted: Int,
        topicsCompleted: Int,
        streakDays: Int,
        studyMinutes: Int,
        lastStudyDate: Date?,
        bookmarkedTopics: [String],
        activityByDay: [String: Int],
        unlockedAchievementIds: [String],
        dailyGoalCards: Int,
        remindersEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int,
        focusSessionsCompleted: Int,
        wrongAnswerCardIds: [UUID],
        cardsReviewedToday: Int,
        cardsReviewedTodayKey: String
    ) {
        self.cardsReviewed = cardsReviewed
        self.quizzesCompleted = quizzesCompleted
        self.topicsCompleted = topicsCompleted
        self.streakDays = streakDays
        self.studyMinutes = studyMinutes
        self.lastStudyDate = lastStudyDate
        self.bookmarkedTopics = bookmarkedTopics
        self.activityByDay = activityByDay
        self.unlockedAchievementIds = unlockedAchievementIds
        self.dailyGoalCards = dailyGoalCards
        self.remindersEnabled = remindersEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.focusSessionsCompleted = focusSessionsCompleted
        self.wrongAnswerCardIds = wrongAnswerCardIds
        self.cardsReviewedToday = cardsReviewedToday
        self.cardsReviewedTodayKey = cardsReviewedTodayKey
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cardsReviewed = try c.decodeIfPresent(Int.self, forKey: .cardsReviewed) ?? 0
        quizzesCompleted = try c.decodeIfPresent(Int.self, forKey: .quizzesCompleted) ?? 0
        topicsCompleted = try c.decodeIfPresent(Int.self, forKey: .topicsCompleted) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        studyMinutes = try c.decodeIfPresent(Int.self, forKey: .studyMinutes) ?? 0
        lastStudyDate = try c.decodeIfPresent(Date.self, forKey: .lastStudyDate)
        bookmarkedTopics = try c.decodeIfPresent([String].self, forKey: .bookmarkedTopics) ?? []
        activityByDay = try c.decodeIfPresent([String: Int].self, forKey: .activityByDay) ?? [:]
        unlockedAchievementIds = try c.decodeIfPresent([String].self, forKey: .unlockedAchievementIds) ?? []
        dailyGoalCards = try c.decodeIfPresent(Int.self, forKey: .dailyGoalCards) ?? 20
        remindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 19
        reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
        focusSessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .focusSessionsCompleted) ?? 0
        wrongAnswerCardIds = try c.decodeIfPresent([UUID].self, forKey: .wrongAnswerCardIds) ?? []
        cardsReviewedToday = try c.decodeIfPresent(Int.self, forKey: .cardsReviewedToday) ?? 0
        cardsReviewedTodayKey = try c.decodeIfPresent(String.self, forKey: .cardsReviewedTodayKey) ?? ""
    }
}
