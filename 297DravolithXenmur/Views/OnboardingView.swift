import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var storage: AppStorageService
    @State private var page = 0

    private let pages: [(title: String, detail: String, image: String)] = [
        ("Welcome", "Enhance your knowledge with efficient study tools.", "bgStudy"),
        ("Create Flashcards", "Generate custom flashcards from your study materials.", "bannerCards"),
        ("Begin Your Journey", "Start by creating your first set of flashcards.", "accentGlow")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 0) {
                        Image(item.image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.42)
                            .clipped()
                            .overlay(alignment: .bottom) {
                                LinearGradient(
                                    colors: [Color("AppBackground").opacity(0), Color("AppBackground")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 80)
                            }

                        VStack(spacing: 16) {
                            Text(item.title)
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(Color("AppTextPrimary"))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(item.detail)
                                .font(.body)
                                .foregroundColor(Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 6) {
                                ForEach(0..<pages.count, id: \.self) { i in
                                    Capsule()
                                        .fill(i == page ? ThemeColor.primary : Color("AppSurface"))
                                        .frame(width: i == page ? 28 : 8, height: 8)
                                }
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color("AppSurface"))
                                .shadow(color: ThemeColor.primary.opacity(0.25), radius: 20, y: -4)
                        )
                        .padding(.horizontal, 16)
                        .offset(y: -28)

                        Spacer(minLength: 0)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PrimaryActionButton(
                title: page == pages.count - 1 ? "Get Started" : "Continue",
                systemImage: page == pages.count - 1 ? "arrow.right.circle.fill" : "chevron.right"
            ) {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    storage.completeOnboarding()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color("AppBackground")
                .ignoresSafeArea()
        }
    }
}
