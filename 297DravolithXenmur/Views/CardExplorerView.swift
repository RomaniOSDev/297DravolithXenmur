import SwiftUI

struct CardExplorerView: View {
    @EnvironmentObject private var storage: AppStorageService
    @State private var searchText = ""
    @State private var selectedTopic: String?
    @State private var selectedTag: String?
    @State private var learningOnly = false
    @State private var dueOnly = false
    @State private var showAddSheet = false
    @State private var flippedIds: Set<UUID> = []
    @State private var reviewCard: Flashcard?

    private var filteredTopics: [String] {
        let topics = storage.topics
        if searchText.isEmpty { return topics }
        return topics.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private var displayedCards: [Flashcard] {
        var base: [Flashcard]
        if let selectedTopic {
            base = storage.cards(for: selectedTopic)
        } else if !searchText.isEmpty {
            base = storage.flashcards.filter {
                $0.front.localizedCaseInsensitiveContains(searchText)
                    || $0.back.localizedCaseInsensitiveContains(searchText)
                    || $0.topic.localizedCaseInsensitiveContains(searchText)
                    || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        } else {
            base = storage.flashcards
        }
        if let selectedTag {
            base = base.filter { $0.tags.contains(selectedTag) }
        }
        if learningOnly {
            base = base.filter { $0.status == .learning }
        }
        if dueOnly {
            base = base.filter(\.isDue)
        }
        return base
    }

    var body: some View {
        NavigationStack {
            Group {
                if storage.flashcards.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .screenBackground()
            .navigationTitle("Card Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticFeedback.light()
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(ThemeColor.primary)
                            .font(.title3)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search cards, topics, tags")
            .sheet(isPresented: $showAddSheet) {
                AddCardsSheet()
                    .environmentObject(storage)
            }
            .sheet(item: $reviewCard) { card in
                SpacedReviewSheet(card: card)
                    .environmentObject(storage)
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateView(
                title: "No Flashcards Yet — Tap Add to Get Started!",
                systemImage: "book.fill"
            )
            PrimaryActionButton(title: "Add Cards", systemImage: "plus") {
                showAddSheet = true
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerBanner
                dueBanner

                filterToggles

                if !filteredTopics.isEmpty {
                    Text("Topics")
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            topicChip(title: "All", selected: selectedTopic == nil) {
                                selectedTopic = nil
                            }
                            ForEach(filteredTopics, id: \.self) { topic in
                                topicChip(title: topic, selected: selectedTopic == topic) {
                                    selectedTopic = topic
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if !storage.allTags.isEmpty {
                    Text("Tags")
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            topicChip(title: "All tags", selected: selectedTag == nil) {
                                selectedTag = nil
                            }
                            ForEach(storage.allTags, id: \.self) { tag in
                                topicChip(title: "#\(tag)", selected: selectedTag == tag) {
                                    selectedTag = tag
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                Text(selectedTopic.map { "Cards · \($0)" } ?? "All Cards")
                    .font(.headline)
                    .foregroundColor(Color("AppTextPrimary"))
                    .padding(.horizontal, 16)

                if displayedCards.isEmpty {
                    EmptyStateView(
                        title: "No matching flashcards",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(displayedCards) { card in
                                FlashcardCarouselItem(
                                    card: card,
                                    isFlipped: flippedIds.contains(card.id),
                                    onFlip: { toggleFlip(card.id) },
                                    onReview: { reviewCard = card }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(displayedCards) { card in
                            FlashcardListRow(
                                card: card,
                                isFlipped: flippedIds.contains(card.id),
                                onFlip: { toggleFlip(card.id) },
                                onReview: { reviewCard = card }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 110)
        }
    }

    private var dueBanner: some View {
        let due = storage.dueCards().count
        return GoldElevatedCard(padding: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(ThemeColor.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(due) card\(due == 1 ? "" : "s") due")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("AppTextPrimary"))
                    Text("Spaced repetition keeps hard cards coming back.")
                        .font(.caption2)
                        .foregroundColor(Color("AppTextSecondary"))
                }
                Spacer()
                if due > 0, let first = storage.dueCards().first {
                    Button("Review") {
                        HapticFeedback.light()
                        reviewCard = first
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(ThemeColor.primary)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var filterToggles: some View {
        HStack(spacing: 10) {
            filterChip("Learning", isOn: $learningOnly)
            filterChip("Due today", isOn: $dueOnly)
        }
        .padding(.horizontal, 16)
    }

    private func filterChip(_ title: String, isOn: Binding<Bool>) -> some View {
        Button {
            HapticFeedback.light()
            isOn.wrappedValue.toggle()
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(isOn.wrappedValue ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color("AppTextPrimary"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isOn.wrappedValue ? ThemeColor.primary : Color("AppSurface"))
                )
        }
        .buttonStyle(.plain)
    }

    private var headerBanner: some View {
        Image("bannerCards")
            .resizable()
            .scaledToFill()
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [.clear, Color("AppBackground").opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                Text("Browse & flip to learn")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("AppTextPrimary"))
                    .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: ThemeColor.primary.opacity(0.3), radius: 12, y: 6)
            .padding(.horizontal, 16)
    }

    private func topicChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticFeedback.light()
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(selected ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color("AppTextPrimary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(selected
                              ? AnyShapeStyle(LinearGradient(colors: [ThemeColor.primary, ThemeColor.accent], startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(Color("AppSurface")))
                )
                .overlay(Capsule().stroke(ThemeColor.primary.opacity(selected ? 0 : 0.35), lineWidth: 1))
                .shadow(color: selected ? ThemeColor.primary.opacity(0.4) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func toggleFlip(_ id: UUID) {
        HapticFeedback.light()
        if flippedIds.contains(id) {
            flippedIds.remove(id)
        } else {
            flippedIds.insert(id)
        }
    }
}

private struct SpacedReviewSheet: View {
    @EnvironmentObject private var storage: AppStorageService
    @Environment(\.dismiss) private var dismiss
    let card: Flashcard
    @State private var revealed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                GoldElevatedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(card.topic.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundColor(ThemeColor.accent)
                        Text(card.front)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Color("AppTextPrimary"))
                        if revealed {
                            Divider()
                            Text(card.back)
                                .font(.title3.weight(.medium))
                                .foregroundColor(ThemeColor.primary)
                            if !card.example.isEmpty {
                                Text("Example")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Color("AppTextSecondary"))
                                Text(card.example)
                                    .foregroundColor(Color("AppTextPrimary"))
                            }
                            if !card.notes.isEmpty {
                                Text("Notes")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Color("AppTextSecondary"))
                                Text(card.notes)
                                    .foregroundColor(Color("AppTextSecondary"))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                if !revealed {
                    PrimaryActionButton(title: "Show Answer", systemImage: "eye.fill") {
                        revealed = true
                    }
                    .padding(.horizontal, 16)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ReviewQuality.allCases) { quality in
                            Button {
                                HapticFeedback.light()
                                storage.reviewWithSM2(id: card.id, quality: quality)
                                SoundPlayer.playSuccess()
                                dismiss()
                            } label: {
                                Label(quality.title, systemImage: quality.systemImage)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color("AppTextPrimary"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color("AppSurface"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                Spacer()
            }
            .padding(.top, 16)
            .screenBackground()
            .navigationTitle("Spaced Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(ThemeColor.primary)
                }
            }
        }
    }
}

private struct FlashcardCarouselItem: View {
    let card: Flashcard
    let isFlipped: Bool
    let onFlip: () -> Void
    let onReview: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color("AppSurface"))
                    .shadow(color: ThemeColor.primary.opacity(0.4), radius: 12, y: 8)

                VStack(spacing: 8) {
                    Text(card.topic.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundColor(ThemeColor.accent)
                    Text(isFlipped ? card.back : card.front)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(Color("AppTextPrimary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    if isFlipped, !card.example.isEmpty {
                        Text(card.example)
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    if !card.tags.isEmpty {
                        Text(card.tags.map { "#\($0)" }.joined(separator: " "))
                            .font(.caption2)
                            .foregroundColor(ThemeColor.primary)
                            .lineLimit(1)
                    }
                }
                .padding(16)
            }
            .frame(width: 260, height: 190)
            .onTapGesture(perform: onFlip)

            Button(action: onReview) {
                Label("Grade (SM-2)", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(LinearGradient(colors: [ThemeColor.primary, ThemeColor.accent], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FlashcardListRow: View {
    let card: Flashcard
    let isFlipped: Bool
    let onFlip: () -> Void
    let onReview: () -> Void

    var body: some View {
        GoldElevatedCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(card.topic)
                        .font(.caption.weight(.bold))
                        .foregroundColor(ThemeColor.accent)
                    Spacer()
                    if card.isDue {
                        Text("Due")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(ThemeColor.primary)
                    }
                    Text(card.status.rawValue.capitalized)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color("AppTextSecondary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color("AppBackground").opacity(0.5)))
                }
                Text(isFlipped ? card.back : card.front)
                    .font(.body.weight(.medium))
                    .foregroundColor(Color("AppTextPrimary"))
                if isFlipped {
                    if !card.example.isEmpty {
                        Text("ex: \(card.example)")
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                    if !card.notes.isEmpty {
                        Text(card.notes)
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }
                if !card.tags.isEmpty {
                    Text(card.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.caption2)
                        .foregroundColor(ThemeColor.primary)
                }
                HStack {
                    Button("Flip", action: onFlip)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ThemeColor.primary)
                    Spacer()
                    Button("Review", action: onReview)
                        .font(.caption.weight(.bold))
                        .foregroundColor(ThemeColor.primary)
                }
            }
        }
    }
}

struct AddCardsSheet: View {
    @EnvironmentObject private var storage: AppStorageService
    @Environment(\.dismiss) private var dismiss

    @State private var topic = ""
    @State private var tagsText = ""
    @State private var front = ""
    @State private var back = ""
    @State private var example = ""
    @State private var notes = ""
    @State private var hint = ""
    @State private var draftCards: [(front: String, back: String, example: String, notes: String, hint: String)] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Topic")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("AppTextSecondary"))
                            TextField("e.g. Biology", text: $topic)
                                .foregroundColor(Color("AppTextPrimary"))
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.55)))
                            Text("Tags (comma-separated)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("AppTextSecondary"))
                            TextField("cells, exam1", text: $tagsText)
                                .foregroundColor(Color("AppTextPrimary"))
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.55)))
                        }
                    }

                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("New Card")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            field("Front (question)", text: $front)
                            field("Back (answer)", text: $back)
                            field("Example", text: $example)
                            field("Notes", text: $notes)
                            field("Hint (optional)", text: $hint)
                            Button {
                                HapticFeedback.light()
                                addDraft()
                            } label: {
                                Label("Add to List", systemImage: "plus")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(ThemeColor.primary)
                            }
                            .buttonStyle(.plain)
                            .disabled(front.trimmingCharacters(in: .whitespaces).isEmpty || back.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    if !draftCards.isEmpty {
                        GoldElevatedCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ready to save (\(draftCards.count))")
                                    .font(.headline)
                                    .foregroundColor(Color("AppTextPrimary"))
                                ForEach(Array(draftCards.enumerated()), id: \.offset) { _, item in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.front)
                                            .foregroundColor(Color("AppTextPrimary"))
                                        Text(item.back)
                                            .font(.caption)
                                            .foregroundColor(Color("AppTextSecondary"))
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    PrimaryActionButton(title: "Save Cards", systemImage: "checkmark.circle.fill") {
                        save()
                    }
                    .disabled(draftCards.isEmpty || topic.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(draftCards.isEmpty || topic.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding(16)
            }
            .dismissKeyboardOnTap()
            .screenBackground()
            .navigationTitle("Add Cards")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.light()
                        dismiss()
                    }
                    .foregroundColor(ThemeColor.primary)
                }
            }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .foregroundColor(Color("AppTextPrimary"))
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.55)))
    }

    private func parsedTags() -> [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func addDraft() {
        let f = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !b.isEmpty else { return }
        draftCards.append((
            f,
            b,
            example.trimmingCharacters(in: .whitespacesAndNewlines),
            notes.trimmingCharacters(in: .whitespacesAndNewlines),
            hint.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        front = ""
        back = ""
        example = ""
        notes = ""
        hint = ""
    }

    private func save() {
        let t = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !draftCards.isEmpty else { return }
        let tags = parsedTags()
        let cards = draftCards.map {
            Flashcard(
                front: $0.front,
                back: $0.back,
                topic: t,
                tags: tags,
                notes: $0.notes,
                example: $0.example,
                hint: $0.hint
            )
        }
        storage.addCards(cards)
        SoundPlayer.playSuccess()
        dismiss()
    }
}
