import Foundation

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let requiredValue: Int
    let metricKey: String
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_review",
            title: "First Review",
            detail: "Review your first flashcard",
            icon: "book.fill",
            requiredValue: 1,
            metricKey: "cardsReviewed"
        ),
        AchievementDefinition(
            id: "dedicated_student",
            title: "Dedicated Student",
            detail: "Complete 10 quizzes",
            icon: "graduationcap.fill",
            requiredValue: 10,
            metricKey: "quizzesCompleted"
        ),
        AchievementDefinition(
            id: "topic_explorer",
            title: "Topic Explorer",
            detail: "Complete 3 topics",
            icon: "map.fill",
            requiredValue: 3,
            metricKey: "topicsCompleted"
        ),
        AchievementDefinition(
            id: "consistent_learner",
            title: "Consistent Learner",
            detail: "Maintain a 7-day streak",
            icon: "flame.fill",
            requiredValue: 7,
            metricKey: "streakDays"
        ),
        AchievementDefinition(
            id: "flashcard_master",
            title: "Flashcard Master",
            detail: "Review 50 flashcards",
            icon: "rectangle.stack.fill",
            requiredValue: 50,
            metricKey: "cardsReviewed"
        ),
        AchievementDefinition(
            id: "quiz_pro",
            title: "Quiz Pro",
            detail: "Complete 25 quizzes",
            icon: "checkmark.seal.fill",
            requiredValue: 25,
            metricKey: "quizzesCompleted"
        ),
        AchievementDefinition(
            id: "time_well_spent",
            title: "Time Well Spent",
            detail: "Study for 500 minutes",
            icon: "clock.fill",
            requiredValue: 500,
            metricKey: "studyMinutes"
        ),
        AchievementDefinition(
            id: "diverse_topics",
            title: "Diverse Topics",
            detail: "Complete 5 topics",
            icon: "globe",
            requiredValue: 5,
            metricKey: "topicsCompleted"
        )
    ]
}
