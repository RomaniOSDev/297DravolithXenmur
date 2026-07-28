import Foundation
import Combine

final class QuizViewModel: ObservableObject {
    @Published var title: String = "Practice Quiz"
    @Published var selectedTopic: String = ""
    @Published var questionCount: Int = 5

    func prepareDefaultTopic(from storage: AppStorageService) {
        if selectedTopic.isEmpty {
            selectedTopic = storage.topics.first ?? ""
        }
    }

    func create(using storage: AppStorageService) -> Quiz? {
        storage.createQuiz(
            title: title.trimmingCharacters(in: .whitespaces).isEmpty ? "Practice Quiz" : title,
            topic: selectedTopic,
            count: questionCount
        )
    }
}
