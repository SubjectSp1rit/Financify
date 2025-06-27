import SwiftUI

struct ShakeGestureModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ShakeGestureView(onShake: action))
    }
}

extension View {
    public func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureModifier(action: action))
    }
}

private struct ShakeGestureView: UIViewRepresentable {
    let onShake: () -> Void
    
    func makeUIView(context: Context) -> ShakeRespondingView {
        let view = ShakeRespondingView()
        view.onShake = onShake
        return view
    }

    func updateUIView(_ uiView: ShakeRespondingView, context: Context) {}
}

private class ShakeRespondingView: UIView {
    var onShake: () -> Void = {}
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake()
        }
        super.motionEnded(motion, with: event)
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponder()
    }
}
