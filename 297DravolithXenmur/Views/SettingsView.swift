import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var storage: AppStorageService
    @EnvironmentObject private var theme: ThemeManager
    @State private var showResetAlert = false
    @State private var soundEnabled = SoundPlayer.isEnabled
    @State private var hapticEnabled = HapticFeedback.isEnabled
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var dailyGoal = 20

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Your Stats")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                counter("Cards", storage.stats.cardsReviewed, "rectangle.stack.fill")
                                counter("Quizzes", storage.stats.quizzesCompleted, "checkmark.circle.fill")
                                counter("Topics", storage.stats.topicsCompleted, "map.fill")
                                counter("Streak", storage.stats.streakDays, "flame.fill")
                                counter("Minutes", storage.stats.studyMinutes, "clock.fill")
                                counter("Cards Saved", storage.flashcards.count, "tray.full.fill")
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Daily Goal")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            Stepper("\(dailyGoal) cards / day", value: $dailyGoal, in: 5...100, step: 5)
                                .foregroundColor(Color("AppTextPrimary"))
                                .onChange(of: dailyGoal) { value in
                                    storage.updateDailyGoal(value)
                                }

                            ProgressView(value: storage.dailyGoalProgress)
                                .tint(ThemeColor.primary)
                            Text("Today: \(storage.stats.cardsReviewedToday)/\(storage.stats.dailyGoalCards)")
                                .font(.caption)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                    .padding(.horizontal, 16)

                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminder")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            Toggle(isOn: $reminderEnabled) {
                                Label("Daily study reminder", systemImage: "bell.fill")
                                    .foregroundColor(Color("AppTextPrimary"))
                            }
                            .tint(ThemeColor.primary)
                            .onChange(of: reminderEnabled) { value in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                                storage.updateReminder(
                                    enabled: value,
                                    hour: comps.hour,
                                    minute: comps.minute
                                )
                            }
                            if reminderEnabled {
                                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .foregroundColor(Color("AppTextPrimary"))
                                    .onChange(of: reminderTime) { value in
                                        let comps = Calendar.current.dateComponents([.hour, .minute], from: value)
                                        storage.updateReminder(
                                            enabled: true,
                                            hour: comps.hour,
                                            minute: comps.minute
                                        )
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    GoldElevatedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            Picker("Mode", selection: $theme.appearance) {
                                ForEach(AppAppearanceMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Accent")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("AppTextSecondary"))
                            HStack(spacing: 12) {
                                ForEach(AccentPreset.allCases) { preset in
                                    Button {
                                        HapticFeedback.light()
                                        theme.accent = preset
                                    } label: {
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(preset.primary)
                                                .frame(width: 28, height: 28)
                                                .overlay(
                                                    Circle().stroke(Color("AppTextPrimary"), lineWidth: theme.accent == preset ? 2 : 0)
                                                )
                                            Text(preset.title)
                                                .font(.caption2)
                                                .foregroundColor(Color("AppTextSecondary"))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    GoldElevatedCard {
                        VStack(spacing: 0) {
                            if SoundPlayer.isAvailable {
                                Toggle(isOn: $soundEnabled) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .foregroundColor(ThemeColor.primary)
                                            .frame(width: 28)
                                        Text("Sound")
                                            .font(.body.weight(.medium))
                                            .foregroundColor(Color("AppTextPrimary"))
                                    }
                                }
                                .tint(ThemeColor.primary)
                                .onChange(of: soundEnabled) { value in
                                    SoundPlayer.isEnabled = value
                                    if value { SoundPlayer.playSuccess() }
                                }

                                Divider()
                                    .background(Color("AppTextSecondary").opacity(0.25))
                                    .padding(.vertical, 8)
                            }

                            Toggle(isOn: $hapticEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundColor(ThemeColor.primary)
                                        .frame(width: 28)
                                    Text("Haptic Feedback")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(Color("AppTextPrimary"))
                                }
                            }
                            .tint(ThemeColor.primary)
                            .onChange(of: hapticEnabled) { value in
                                HapticFeedback.isEnabled = value
                                if value { HapticFeedback.light() }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    settingsRow(title: "Rate Us", icon: "star.fill") {
                        requestReview()
                    }

                    settingsRow(title: "Privacy Policy", icon: "hand.raised.fill") {
                        UIApplication.shared.open(AppLinks.privacy)
                    }

                    settingsRow(title: "Terms of Use", icon: "doc.text.fill") {
                        UIApplication.shared.open(AppLinks.terms)
                    }

                    PrimaryActionButton(title: "Reset All Data", systemImage: "trash.fill", isDestructive: true) {
                        showResetAlert = true
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 110)
            }
            .screenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                dailyGoal = storage.stats.dailyGoalCards
                reminderEnabled = storage.stats.remindersEnabled
                var comps = DateComponents()
                comps.hour = storage.stats.reminderHour
                comps.minute = storage.stats.reminderMinute
                reminderTime = Calendar.current.date(from: comps) ?? Date()
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    HapticFeedback.light()
                    storage.resetAllData()
                }
            } message: {
                Text("This will permanently delete all flashcards, quizzes, and progress.")
            }
        }
    }

    private func counter(_ title: String, _ value: Int, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(ThemeColor.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(Color("AppTextPrimary"))
                Text(title)
                    .font(.caption2)
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.45)))
    }

    private func settingsRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticFeedback.light()
            action()
        } label: {
            GoldElevatedCard {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(ThemeColor.primary)
                        .frame(width: 28)
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundColor(Color("AppTextPrimary"))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
