import SwiftUI

struct StudyHubView: View {
    @State private var mode = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    Text("Quiz").tag(0)
                    Text("Focus").tag(1)
                    Text("Stats").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)

                switch mode {
                case 0:
                    StudyQuizView()
                case 1:
                    FocusTimerView()
                default:
                    StudyDashboardView()
                }
            }
            .screenBackground()
            .navigationTitle("Study")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StudyQuizView: View {
    @EnvironmentObject private var storage: AppStorageService
    @State private var showCreate = false
    @State private var activeQuiz: Quiz?
    @State private var showSummary: QuizResult?

    var body: some View {
        Group {
            if storage.flashcards.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(
                        title: "Create your first quiz after adding flashcards!",
                        systemImage: "lightbulb.fill",
                        subtitle: "Add cards in Explore, then come back to quiz yourself."
                    )
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Image("accentGlow")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .overlay {
                                LinearGradient(
                                    colors: [Color("AppBackground").opacity(0.2), Color("AppBackground").opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                            .overlay(alignment: .bottomLeading) {
                                Text("Challenge yourself")
                                    .font(.headline)
                                    .foregroundColor(Color("AppTextPrimary"))
                                    .padding(12)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: ThemeColor.primary.opacity(0.3), radius: 10, y: 5)
                            .padding(.horizontal, 16)

                        dailyGoalStrip

                        PrimaryActionButton(title: "Create Quiz", systemImage: "plus.circle.fill") {
                            showCreate = true
                        }
                        .padding(.horizontal, 16)

                        if !storage.wrongAnswerCards().isEmpty {
                            PrimaryActionButton(title: "Review Mistakes (\(storage.wrongAnswerCards().count))", systemImage: "arrow.triangle.2.circlepath") {
                                if let quiz = storage.createWrongAnswersQuiz() {
                                    activeQuiz = quiz
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if storage.quizzes.isEmpty {
                            EmptyStateView(
                                title: "No quizzes yet — create one to begin!",
                                systemImage: "lightbulb.fill"
                            )
                        } else {
                            Text("Your Quizzes")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                                .padding(.horizontal, 16)

                            ForEach(storage.quizzes) { quiz in
                                GoldElevatedCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(quiz.title)
                                                .font(.headline)
                                                .foregroundColor(Color("AppTextPrimary"))
                                            Text("\(quiz.topic) · \(quiz.cardIds.count) · \(quiz.mode.title)")
                                                .font(.caption)
                                                .foregroundColor(Color("AppTextSecondary"))
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(ThemeColor.primary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    HapticFeedback.light()
                                    activeQuiz = quiz
                                }
                            }
                        }

                        if !storage.quizResults.isEmpty {
                            Text("Recent Scores")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                                .padding(.horizontal, 16)
                            ForEach(storage.quizResults.prefix(5)) { result in
                                GoldElevatedCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.quizTitle)
                                                .foregroundColor(Color("AppTextPrimary"))
                                            Text("\(result.score)/\(result.total)")
                                                .font(.caption)
                                                .foregroundColor(Color("AppTextSecondary"))
                                        }
                                        Spacer()
                                        Text("\(result.percentage)%")
                                            .font(.title3.weight(.bold))
                                            .foregroundColor(ThemeColor.primary)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 110)
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateQuizSheet { quiz in
                activeQuiz = quiz
            }
            .environmentObject(storage)
        }
        .fullScreenCover(item: $activeQuiz) { quiz in
            QuizSessionView(quiz: quiz) { result in
                showSummary = result
            }
            .environmentObject(storage)
        }
        .sheet(item: $showSummary) { result in
            QuizSummaryView(result: result) {
                if !result.missedCardIds.isEmpty, let quiz = storage.createWrongAnswersQuiz() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        activeQuiz = quiz
                    }
                }
            }
            .environmentObject(storage)
        }
    }

    private var dailyGoalStrip: some View {
        GoldElevatedCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily goal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("AppTextPrimary"))
                    Spacer()
                    Text("\(storage.stats.cardsReviewedToday)/\(storage.stats.dailyGoalCards)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(ThemeColor.primary)
                }
                ProgressView(value: storage.dailyGoalProgress)
                    .tint(ThemeColor.primary)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct CreateQuizSheet: View {
    @EnvironmentObject private var storage: AppStorageService
    @Environment(\.dismiss) private var dismiss
    var onCreated: (Quiz) -> Void

    @State private var title = "Practice Quiz"
    @State private var topic = ""
    @State private var count = 5
    @State private var mode: QuizMode = .multipleChoice

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quiz Title")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("AppTextSecondary"))
                            TextField("Title", text: $title)
                                .foregroundColor(Color("AppTextPrimary"))
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.55)))

                            Text("Topic")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("AppTextSecondary"))
                            if storage.topics.isEmpty {
                                Text("Add flashcards first")
                                    .foregroundColor(Color("AppTextSecondary"))
                            } else {
                                Picker("Topic", selection: $topic) {
                                    ForEach(storage.topics, id: \.self) { t in
                                        Text(t).tag(t)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(ThemeColor.primary)
                            }

                            Text("Mode")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("AppTextSecondary"))
                            Picker("Mode", selection: $mode) {
                                ForEach(QuizMode.allCases) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)

                            Stepper("Questions: \(count)", value: $count, in: 1...20)
                                .foregroundColor(Color("AppTextPrimary"))
                        }
                    }

                    PrimaryActionButton(title: "Start Quiz", systemImage: "play.fill") {
                        guard let quiz = storage.createQuiz(
                            title: title.trimmingCharacters(in: .whitespaces).isEmpty ? "Practice Quiz" : title,
                            topic: topic,
                            count: count,
                            mode: mode
                        ) else { return }
                        SoundPlayer.playSuccess()
                        dismiss()
                        onCreated(quiz)
                    }
                    .disabled(topic.isEmpty)
                    .opacity(topic.isEmpty ? 0.5 : 1)
                }
                .padding(16)
            }
            .dismissKeyboardOnTap()
            .screenBackground()
            .navigationTitle("Create Quiz")
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
            .onAppear {
                if topic.isEmpty {
                    topic = storage.topics.first ?? ""
                }
            }
        }
    }
}

struct QuizSessionView: View {
    @EnvironmentObject private var storage: AppStorageService
    @Environment(\.dismiss) private var dismiss

    let quiz: Quiz
    var onComplete: (QuizResult) -> Void

    @State private var questions: [QuizQuestion] = []
    @State private var index = 0
    @State private var selected: String?
    @State private var typedAnswer = ""
    @State private var score = 0
    @State private var answered = false
    @State private var missed: [UUID] = []
    @State private var mistakesOnCurrent = 0
    @State private var showHint = false
    @State private var lastWrong = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if questions.isEmpty {
                    ProgressView()
                        .tint(ThemeColor.primary)
                } else {
                    progressHeader
                    questionCard
                    answerArea
                    if showHint {
                        hintBanner
                    }
                    if lastWrong && !answered {
                        Text("Not quite — try again")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.red)
                    }
                    Spacer()
                    PrimaryActionButton(
                        title: answered ? (index + 1 >= questions.count ? "Finish" : "Next") : "Submit",
                        systemImage: answered ? "arrow.right" : "checkmark"
                    ) {
                        advance()
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                    .padding(.horizontal, 16)

                    if lastWrong && !answered {
                        Button("Skip question") {
                            HapticFeedback.light()
                            goNext(markMissed: true)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("AppTextSecondary"))
                        .padding(.bottom, 12)
                    } else {
                        Color.clear.frame(height: 8)
                            .padding(.bottom, 12)
                    }
                }
            }
            .dismissKeyboardOnTap()
            .screenBackground()
            .navigationTitle(quiz.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        HapticFeedback.light()
                        dismiss()
                    }
                    .foregroundColor(ThemeColor.primary)
                }
            }
            .onAppear {
                questions = storage.questions(for: quiz)
            }
        }
    }

    private var canSubmit: Bool {
        if answered { return true }
        switch quiz.mode {
        case .typed:
            return !typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return selected != nil
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question \(index + 1) of \(questions.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color("AppTextSecondary"))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color("AppSurface"))
                    Capsule()
                        .fill(LinearGradient(colors: [ThemeColor.primary, ThemeColor.accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(index + 1) / CGFloat(max(questions.count, 1)))
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 16)
    }

    private var questionCard: some View {
        GoldElevatedCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(questions[index].card.topic.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(ThemeColor.accent)
                Text(questions[index].prompt)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color("AppTextPrimary"))
                if quiz.mode == .trueFalse {
                    Text("Is this answer correct for the question?")
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var answerArea: some View {
        switch quiz.mode {
        case .multipleChoice, .trueFalse:
            optionsList
        case .typed:
            typedField
        }
    }

    private var typedField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Type your answer", text: $typedAnswer)
                .disabled(answered)
                .foregroundColor(Color("AppTextPrimary"))
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color("AppSurface")))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(answered
                                ? (isTypedCorrect ? ThemeColor.primary : Color.red)
                                : ThemeColor.primary.opacity(0.4), lineWidth: 1.5)
                )
            if answered {
                Text(isTypedCorrect ? "Correct" : "Answer: \(questions[index].correctAnswer)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isTypedCorrect ? ThemeColor.primary : .red)
            }
        }
        .padding(.horizontal, 16)
    }

    private var isTypedCorrect: Bool {
        storage.answersMatch(typedAnswer, correct: questions[index].correctAnswer)
    }

    private var optionsList: some View {
        VStack(spacing: 10) {
            ForEach(questions[index].options, id: \.self) { option in
                Button {
                    guard !answered else { return }
                    HapticFeedback.light()
                    selected = option
                } label: {
                    HStack {
                        Text(option)
                            .foregroundColor(Color("AppTextPrimary"))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if answered {
                            if option == questions[index].correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ThemeColor.primary)
                            } else if option == selected {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        } else if selected == option {
                            Image(systemName: "circle.fill")
                                .foregroundColor(ThemeColor.primary)
                                .font(.caption)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(optionBackground(option))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected == option ? ThemeColor.primary : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var hintBanner: some View {
        GoldElevatedCard(padding: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(ThemeColor.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hint")
                        .font(.caption.weight(.bold))
                        .foregroundColor(ThemeColor.primary)
                    Text(questions[index].card.displayHint)
                        .font(.subheadline)
                        .foregroundColor(Color("AppTextPrimary"))
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func optionBackground(_ option: String) -> Color {
        if answered {
            if option == questions[index].correctAnswer {
                return ThemeColor.primary.opacity(0.25)
            }
            if option == selected {
                return Color.red.opacity(0.2)
            }
        }
        return Color("AppSurface")
    }

    private func isCurrentCorrect() -> Bool {
        switch quiz.mode {
        case .typed:
            return isTypedCorrect
        default:
            return selected == questions[index].correctAnswer
        }
    }

    private func advance() {
        HapticFeedback.light()
        if !answered {
            if isCurrentCorrect() {
                answered = true
                lastWrong = false
                score += 1
                SoundPlayer.playSuccess()
            } else {
                mistakesOnCurrent += 1
                lastWrong = true
                if !missed.contains(questions[index].card.id) {
                    missed.append(questions[index].card.id)
                }
                if mistakesOnCurrent >= 2 {
                    showHint = true
                }
                selected = nil
                typedAnswer = ""
            }
            return
        }
        goNext(markMissed: false)
    }

    private func goNext(markMissed: Bool) {
        if markMissed, !missed.contains(questions[index].card.id) {
            missed.append(questions[index].card.id)
        }
        if index + 1 >= questions.count {
            storage.submitQuiz(
                quiz: quiz,
                score: score,
                total: questions.count,
                missedCardIds: Array(Set(missed))
            )
            let result = QuizResult(
                quizId: quiz.id,
                quizTitle: quiz.title,
                score: score,
                total: questions.count,
                missedCardIds: Array(Set(missed)),
                mode: quiz.mode
            )
            dismiss()
            onComplete(result)
        } else {
            index += 1
            selected = nil
            typedAnswer = ""
            answered = false
            mistakesOnCurrent = 0
            showHint = false
            lastWrong = false
        }
    }
}

struct QuizSummaryView: View {
    let result: QuizResult
    var onReviewMistakes: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: result.percentage >= 70 ? "star.circle.fill" : "flag.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(colors: [ThemeColor.primary, ThemeColor.accent], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: ThemeColor.primary.opacity(0.5), radius: 12)
                Text("Quiz Complete")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Color("AppTextPrimary"))
                Text(result.quizTitle)
                    .foregroundColor(Color("AppTextSecondary"))
                GoldElevatedCard {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Score")
                                .font(.caption)
                                .foregroundColor(Color("AppTextSecondary"))
                            Text("\(result.score) / \(result.total)")
                                .font(.title.weight(.bold))
                                .foregroundColor(Color("AppTextPrimary"))
                        }
                        Spacer()
                        Text("\(result.percentage)%")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(ThemeColor.primary)
                    }
                }
                .padding(.horizontal, 24)
                Spacer()
                if !result.missedCardIds.isEmpty {
                    PrimaryActionButton(title: "Review Mistakes", systemImage: "arrow.triangle.2.circlepath") {
                        dismiss()
                        onReviewMistakes?()
                    }
                    .padding(.horizontal, 24)
                }
                PrimaryActionButton(title: "Done", systemImage: "checkmark") {
                    dismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .screenBackground()
            .navigationBarHidden(true)
            .onAppear { SoundPlayer.playSuccess() }
        }
    }
}
