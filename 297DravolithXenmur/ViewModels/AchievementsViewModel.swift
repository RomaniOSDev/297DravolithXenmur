import Foundation
import Combine

final class AchievementsViewModel: ObservableObject {
    func definitions() -> [AchievementDefinition] {
        AchievementCatalog.all
    }

    func progress(for definition: AchievementDefinition, stats: StudyStats) -> Double {
        let current = stats.metricValue(for: definition.metricKey)
        return min(Double(current) / Double(max(definition.requiredValue, 1)), 1)
    }
}
