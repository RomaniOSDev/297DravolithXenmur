import Foundation
import Combine

final class DashboardViewModel: ObservableObject {
    @Published var range: DashboardRange = .daily

    func progress(from storage: AppStorageService) -> [TopicProgress] {
        storage.topicProgressList()
    }

    func activity(from storage: AppStorageService) -> [(label: String, value: Int)] {
        storage.activityCounts(for: range)
    }
}
