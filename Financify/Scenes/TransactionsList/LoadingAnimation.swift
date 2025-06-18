import SwiftUI

struct LoadingAnimation: View {
    // MARK: - Properties
    @State private var start = false
    
    var body: some View {
        ZStack {
            Text(verbatim: .loadingText)
                .foregroundColor(.secondary)
            
            Text(verbatim: .loadingText)
                .foregroundColor(.white)
            .frame(width: .loadingLabelWidth, height: .loadingLabelHeight)
                .background(.accent)
                .mask {
                    CircleInside(start: $start)
                }
            
            CircleOutside(start: $start)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            withAnimation(.easeInOut(duration: .animationDuration).repeatForever(autoreverses: true)) {
                start = true
            }
        }
    }
}

struct CircleInside: View {
    @Binding var start: Bool
    
    var body: some View {
        Circle()
            .frame(width: .circleSide, height: .circleSide)
            .offset(x: start ? .startOffsetX : .endOffsetX)
    }
}

struct CircleOutside: View {
    @Binding var start: Bool
    
    var body: some View {
        Circle()
            .stroke(.accent, lineWidth: .circleOutsizeStrokeWidth)
            .frame(width: .circleSide, height: .circleSide)
            .offset(x: start ? .startOffsetX : .endOffsetX)
    }
}

// MARK: - Constants
fileprivate extension String {
    static let loadingText: String = "Загрузка..."
}

fileprivate extension CGFloat {
    static let loadingLabelWidth: CGFloat = 200
    static let loadingLabelHeight: CGFloat = 200
    
    static let circleSide: CGFloat = 40
    static let circleOutsizeStrokeWidth: CGFloat = 5
    
    static let startOffsetX: CGFloat = -30
    static let endOffsetX: CGFloat = 30
}

fileprivate extension Double {
    static let animationDuration: Double = 1
}

// MARK: - Preview
#Preview {
    LoadingAnimation()
}
