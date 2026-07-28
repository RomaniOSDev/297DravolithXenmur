import Foundation

enum CardStatus: String, Codable, CaseIterable {
    case new
    case learning
    case known
}

struct Flashcard: Identifiable, Codable, Equatable {
    var id: UUID
    var front: String
    var back: String
    var topic: String
    var status: CardStatus
    var createdAt: Date
    var tags: [String]
    var notes: String
    var example: String
    var hint: String
    var easinessFactor: Double
    var repetition: Int
    var intervalDays: Int
    var nextReviewDate: Date?
    var lastReviewedAt: Date?

    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        topic: String,
        status: CardStatus = .new,
        createdAt: Date = Date(),
        tags: [String] = [],
        notes: String = "",
        example: String = "",
        hint: String = "",
        easinessFactor: Double = 2.5,
        repetition: Int = 0,
        intervalDays: Int = 0,
        nextReviewDate: Date? = Date(),
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.topic = topic
        self.status = status
        self.createdAt = createdAt
        self.tags = tags
        self.notes = notes
        self.example = example
        self.hint = hint
        self.easinessFactor = easinessFactor
        self.repetition = repetition
        self.intervalDays = intervalDays
        self.nextReviewDate = nextReviewDate
        self.lastReviewedAt = lastReviewedAt
    }

    var isDue: Bool {
        guard let next = nextReviewDate else { return true }
        return next <= Date()
    }

    var displayHint: String {
        let trimmed = hint.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let answer = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return "No hint available" }
        let first = String(answer.prefix(1))
        return "Starts with “\(first)” · \(answer.count) characters"
    }

    enum CodingKeys: String, CodingKey {
        case id, front, back, topic, status, createdAt
        case tags, notes, example, hint
        case easinessFactor, repetition, intervalDays, nextReviewDate, lastReviewedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        front = try c.decode(String.self, forKey: .front)
        back = try c.decode(String.self, forKey: .back)
        topic = try c.decode(String.self, forKey: .topic)
        status = try c.decode(CardStatus.self, forKey: .status)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        example = try c.decodeIfPresent(String.self, forKey: .example) ?? ""
        hint = try c.decodeIfPresent(String.self, forKey: .hint) ?? ""
        easinessFactor = try c.decodeIfPresent(Double.self, forKey: .easinessFactor) ?? 2.5
        repetition = try c.decodeIfPresent(Int.self, forKey: .repetition) ?? 0
        intervalDays = try c.decodeIfPresent(Int.self, forKey: .intervalDays) ?? 0
        nextReviewDate = try c.decodeIfPresent(Date.self, forKey: .nextReviewDate) ?? createdAt
        lastReviewedAt = try c.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
    }
}
