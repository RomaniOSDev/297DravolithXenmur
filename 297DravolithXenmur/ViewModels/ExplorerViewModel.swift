import Foundation
import Combine

final class ExplorerViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedTopic: String?

    func filteredTopics(from storage: AppStorageService) -> [String] {
        let topics = storage.topics
        guard !searchText.isEmpty else { return topics }
        return topics.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    func displayedCards(from storage: AppStorageService) -> [Flashcard] {
        if let selectedTopic {
            return storage.cards(for: selectedTopic)
        }
        if !searchText.isEmpty {
            return storage.flashcards.filter {
                $0.front.localizedCaseInsensitiveContains(searchText)
                    || $0.back.localizedCaseInsensitiveContains(searchText)
                    || $0.topic.localizedCaseInsensitiveContains(searchText)
            }
        }
        return storage.flashcards
    }
}
