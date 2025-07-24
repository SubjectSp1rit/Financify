import SwiftUI
import Lottie

public struct LaunchAnimationView: View {
    private let animationName: String
    private let onFinished: () -> Void

    public init(
        animationName: String = "pig",
        onFinished: @escaping () -> Void
    ) {
        self.animationName = animationName
        self.onFinished = onFinished
    }

    public var body: some View {
        LottieRepresentable(
            animationName: animationName,
            onFinished: onFinished
        )
        .ignoresSafeArea()
    }
}

private struct LottieRepresentable: UIViewRepresentable {
    typealias UIViewType = LottieAnimationView

    let animationName: String
    let onFinished: () -> Void

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: animationName, bundle: .module)
        view.contentMode = .scaleAspectFit
        view.loopMode = .playOnce
        view.backgroundBehavior = .pauseAndRestore

        view.play { _ in
            onFinished()
        }
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) { }
}
