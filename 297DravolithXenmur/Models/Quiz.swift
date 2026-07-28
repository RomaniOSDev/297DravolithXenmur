import Foundation

enum QuizMode: String, Codable, CaseIterable, Identifiable {
    case multipleChoice
    case trueFalse
    case typed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .trueFalse: return "True / False"
        case .typed: return "Type Answer"
        }
    }
}

struct Quiz: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var topic: String
    var cardIds: [UUID]
    var createdAt: Date
    var mode: QuizMode

    init(
        id: UUID = UUID(),
        title: String,
        topic: String,
        cardIds: [UUID],
        createdAt: Date = Date(),
        mode: QuizMode = .multipleChoice
    ) {
        self.id = id
        self.title = title
        self.topic = topic
        self.cardIds = cardIds
        self.createdAt = createdAt
        self.mode = mode
    }

    enum CodingKeys: String, CodingKey {
        case id, title, topic, cardIds, createdAt, mode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        topic = try c.decode(String.self, forKey: .topic)
        cardIds = try c.decode([UUID].self, forKey: .cardIds)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        mode = try c.decodeIfPresent(QuizMode.self, forKey: .mode) ?? .multipleChoice
    }
}

struct QuizResult: Identifiable, Codable, Equatable {
    var id: UUID
    var quizId: UUID
    var quizTitle: String
    var score: Int
    var total: Int
    var completedAt: Date
    var missedCardIds: [UUID]
    var mode: QuizMode

    init(
        id: UUID = UUID(),
        quizId: UUID,
        quizTitle: String,
        score: Int,
        total: Int,
        completedAt: Date = Date(),
        missedCardIds: [UUID] = [],
        mode: QuizMode = .multipleChoice
    ) {
        self.id = id
        self.quizId = quizId
        self.quizTitle = quizTitle
        self.score = score
        self.total = total
        self.completedAt = completedAt
        self.missedCardIds = missedCardIds
        self.mode = mode
    }

    var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(score) / Double(total)) * 100)
    }

    enum CodingKeys: String, CodingKey {
        case id, quizId, quizTitle, score, total, completedAt, missedCardIds, mode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        quizId = try c.decode(UUID.self, forKey: .quizId)
        quizTitle = try c.decode(String.self, forKey: .quizTitle)
        score = try c.decode(Int.self, forKey: .score)
        total = try c.decode(Int.self, forKey: .total)
        completedAt = try c.decode(Date.self, forKey: .completedAt)
        missedCardIds = try c.decodeIfPresent([UUID].self, forKey: .missedCardIds) ?? []
        mode = try c.decodeIfPresent(QuizMode.self, forKey: .mode) ?? .multipleChoice
    }
}

struct QuizQuestion: Identifiable {
    let id: UUID
    let card: Flashcard
    let options: [String]
    let correctAnswer: String
    let mode: QuizMode
    /// For true/false: whether the shown statement is true.
    let statementIsTrue: Bool
    let prompt: String
}
