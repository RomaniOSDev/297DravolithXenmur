import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func resign() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private struct WindowTapKeyboardDismiss: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
            tap.cancelsTouchesInView = false
            tap.delegate = context.coordinator
            window.addGestureRecognizer(tap)
            context.coordinator.attachedWindow = window
            context.coordinator.recognizer = tap
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        if let recognizer = coordinator.recognizer {
            coordinator.attachedWindow?.removeGestureRecognizer(recognizer)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var attachedWindow: UIWindow?
        weak var recognizer: UITapGestureRecognizer?

        @objc func handleTap() {
            KeyboardDismiss.resign()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        background(WindowTapKeyboardDismiss())
    }
}
