import Foundation

enum ReviewQuality: Int, CaseIterable, Identifiable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var systemImage: String {
        switch self {
        case .again: return "arrow.counterclockwise"
        case .hard: return "tortoise.fill"
        case .good: return "checkmark"
        case .easy: return "bolt.fill"
        }
    }
}

enum SM2Engine {
    /// Classic SM-2 update. Quality 0–5; we map UI 1–4 → 1,3,4,5.
    static func apply(quality: ReviewQuality, to card: inout Flashcard) {
        let q: Int
        switch quality {
        case .again: q = 1
        case .hard: q = 3
        case .good: q = 4
        case .easy: q = 5
        }

        var ef = card.easinessFactor
        ef = ef + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        if ef < 1.3 { ef = 1.3 }
        card.easinessFactor = ef

        if q < 3 {
            card.repetition = 0
            card.intervalDays = 1
            card.status = .learning
        } else {
            if card.repetition == 0 {
                card.intervalDays = 1
            } else if card.repetition == 1 {
                card.intervalDays = quality == .easy ? 4 : 3
            } else {
                card.intervalDays = Int((Double(card.intervalDays) * ef).rounded())
            }
            card.repetition += 1
            card.status = card.intervalDays >= 21 ? .known : .learning
        }

        card.lastReviewedAt = Date()
        card.nextReviewDate = Calendar.current.date(byAdding: .day, value: max(card.intervalDays, 1), to: Date())
    }
}
