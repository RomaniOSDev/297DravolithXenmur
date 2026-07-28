import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject private var storage: AppStorageService
    @State private var selectedMinutes = 10
    @State private var remainingSeconds = 10 * 60
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var showSummary = false
    @State private var completedMinutes = 0
    @State private var timer: Timer?

    private let presets = [5, 10, 25]

    var body: some View {
        VStack(spacing: 20) {
            Text("Focus Mode")
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            GoldElevatedCard {
                VStack(spacing: 16) {
                    Text(timeString(remainingSeconds))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AppTextPrimary"))
                        .monospacedDigit()

                    if !isRunning && !isPaused {
                        HStack(spacing: 10) {
                            ForEach(presets, id: \.self) { minutes in
                                Button {
                                    HapticFeedback.light()
                                    selectedMinutes = minutes
                                    remainingSeconds = minutes * 60
                                } label: {
                                    Text("\(minutes)m")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(selectedMinutes == minutes ? Color("AppBackground") : Color("AppTextPrimary"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(selectedMinutes == minutes ? ThemeColor.primary : Color("AppBackground").opacity(0.45))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        if isRunning {
                            PrimaryActionButton(title: "Pause", systemImage: "pause.fill") {
                                pause()
                            }
                        } else if isPaused {
                            PrimaryActionButton(title: "Resume", systemImage: "play.fill") {
                                resume()
                            }
                        } else {
                            PrimaryActionButton(title: "Start Focus", systemImage: "timer") {
                                start()
                            }
                        }
                    }

                    if isRunning || isPaused {
                        Button {
                            HapticFeedback.light()
                            stop(completed: false)
                        } label: {
                            Text("Cancel")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)

            Text("Stay on one topic until the timer ends. Pausing keeps your progress.")
                .font(.caption)
                .foregroundColor(Color("AppTextSecondary"))
                .padding(.horizontal, 16)

            Spacer()
        }
        .onDisappear { invalidateTimer() }
        .sheet(isPresented: $showSummary) {
            NavigationStack {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundColor(ThemeColor.primary)
                    Text("Focus Complete")
                        .font(.title.weight(.bold))
                        .foregroundColor(Color("AppTextPrimary"))
                    Text("You studied for \(completedMinutes) minute\(completedMinutes == 1 ? "" : "s").")
                        .foregroundColor(Color("AppTextSecondary"))
                    Spacer()
                    PrimaryActionButton(title: "Done", systemImage: "checkmark") {
                        showSummary = false
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .screenBackground()
                .navigationBarHidden(true)
            }
        }
    }

    private func start() {
        remainingSeconds = selectedMinutes * 60
        isRunning = true
        isPaused = false
        tick()
    }

    private func pause() {
        isRunning = false
        isPaused = true
        invalidateTimer()
    }

    private func resume() {
        isRunning = true
        isPaused = false
        tick()
    }

    private func stop(completed: Bool) {
        invalidateTimer()
        isRunning = false
        isPaused = false
        if completed {
            completedMinutes = selectedMinutes
            storage.recordFocusSession(minutes: selectedMinutes)
            SoundPlayer.playSuccess()
            showSummary = true
        }
        remainingSeconds = selectedMinutes * 60
    }

    private func tick() {
        invalidateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds <= 1 {
                stop(completed: true)
            } else {
                remainingSeconds -= 1
            }
        }
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timeString(_ total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
