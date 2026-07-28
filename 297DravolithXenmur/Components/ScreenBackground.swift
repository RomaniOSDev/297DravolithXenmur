import SwiftUI

struct ScreenBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("bgStudy")
                            .resizable()
                            .scaledToFill()
                            .opacity(colorScheme == .dark ? 0.35 : 0.12)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackgroundModifier())
    }
}
